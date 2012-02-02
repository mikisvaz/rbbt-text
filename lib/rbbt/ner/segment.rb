require 'rbbt/annotations'
require 'rbbt/fix_width_table'

module Segment 
  extend Annotation
  self.annotation :offset

  def offset=(offset)
    @offset = offset.nil? ? nil : offset.to_i
  end

  #{{{ Ranges

  def end
    return nil if offset.nil?
    offset + length - 1
  end

  def range
    raise "No offset specified" if offset.nil?
    (offset..self.end)
  end

  def pull(offset)
    if self.offset.nil? or offset.nil?
      self.offset = nil
    else
      self.offset += offset 
    end

    self
  end

  def push(offset)
    if self.offset.nil? or offset.nil?
      self.offset = nil
    else
      self.offset -= offset 
    end

    self
  end

  def make_relative(segments)
    segments.collect{|s| s.push offset}
  end

  def range_in(container = nil)
    raise "No offset specified" if offset.nil?
    case
    when (Segment === container and not container.offset.nil?)
      ((offset - container.offset)..(self.end - container.offset))
    when Integer === container
      ((offset - container)..(self.end - container))
    else
      range
    end
  end

  #{{{ Sorting

  def self.sort(segments, inline = true)
    if inline
      segments.sort do |a,b| 
        case
        when ((a.nil? and b.nil?) or (a.offset.nil? and b.offset.nil?))
          0
        when (a.nil? or a.offset.nil?)
          -1
        when (b.nil? or b.offset.nil?)
          +1
        when (not a.range.include? b.offset and not b.range.include? a.offset)
          a.offset <=> b.offset
        else
          a.length <=> b.length
        end
      end
    else
      segments.sort_by do |segment| segment.offset || 0 end.reverse
    end
  end

  def self.overlaps(sorted_segments)

    last = nil
    overlaped = []
    sorted_segments.reverse.each do |segment| 
      overlaped << segment if (not last.nil?) and segment.range.end > last 
      last = segment.range.begin
    end

    overlaped
  end

  def self.clean_sort(segments)
    sorted = sort(segments).reject{|s| s.offset.nil?}
    overlaps = overlaps(sorted)
    overlaps.each do |s|
      sorted.delete s
    end

    sorted
  end

  #{{{ Splitting

  def self.split(text, segments, skip_segments = false)
    sorted_segments = clean_sort segments

    chunks      = []
    segment_end = 0
    text_offset = 0
    sorted_segments.each do |segment|
      return chunks if text.nil? or text.empty?
      next if segment.offset.nil?
      offset = segment.offset - text_offset

      # Consider segment offset. Save pre, or skip if overlap
      case
      when offset < 0 # Overlap, skip
        next
      when offset > 0 # Save pre
        chunk = text[0..offset - 1]
        Segment.setup(chunk, text_offset)
        chunks << chunk
      end

      segment_end = offset + segment.length - 1

      if not skip_segments
        chunk = text[offset..segment_end]
        Segment.setup(chunk, text_offset + offset)
        chunks << chunk
      end

      text_offset += segment_end + 1
      text = text[segment_end + 1..-1]

    end

    if not text.nil? and text.any?
      chunk = text.dup
      Segment.setup(chunk, text_offset)
      chunks << chunk
    end

    chunks
  end


  #{{{ Align

  def self.align(text, parts)
    pre_offset = 0
    parts.each do |part|
      offset = text.index part
      next if offset.nil?
      Segment.setup(part, pre_offset + offset)
      pre_offset += offset + part.length - 1
      text = text[(offset + part.length - 1)..-1]
    end
  end

  #{{{ Index

  class Index
    attr_accessor :index, :data
    def initialize(index, data)
      @index = index
      @data = data
    end

    def [](pos)
      index[pos].collect{|id| data[id]}
    end
  end

  def self.index(segments, persist_file = :memory)
    segments = segments.values.flatten if Hash === segments

    annotation_index = 
      Persist.persist("Segment_index", :fwt, :persist => (! (persist_file.nil? or persist_file == :memory)), :file => persist_file) do

        value_size = 0
        index_data = segments.collect{|segment| 
          next if segment.offset.nil?
          range = segment.range
          value_size = [segment.id.length, value_size].max
          [segment.id, [range.begin, range.end]]
        }.compact

        fwt = FixWidthTable.get :memory, value_size, true
        fwt.add_range index_data

        fwt
      end

    data = {}
    segments.each do |segment| data[segment.id] = segment end
    Index.new annotation_index, data
  end

  #{{{ Save and load

  def self.tsv_values_for_segment(segment, fields)
    info = segment.info
    values = []

    fields.each do |field|
      values << case
      when field == "JSON"
        info.to_json
      when field == "literal"
        segment.gsub(/\n|\t/, ' ')
      when field == "Start"
        segment.offset
      when field == "End"
        segment.end
      else
        info.delete(field.to_sym)
      end
    end

    values
  end

  def self.load_tsv_values(text, values, fields)
    info = {}
    literal_pos = fields.index "literal"

    object = if literal_pos.nil?
               ""
             else
               v = values[literal_pos]
               v = v.first if Array === v
               v
             end

    fields.each_with_index do |field, i|
      if field == "JSON"
        JSON.parse(values[i]).each do |key, value|
          info[key.to_sym] = value
        end
      else
        info[field.to_sym] = values[i]
      end
    end

    start = info.delete(:Start)
    if not (start.nil? or ((Array === start or String === start) and start.empty?))
      if Array === start
        start = start.first
      end
      start = start.to_i
      info[:offset] = start

      eend = info.delete(:End)
      if Array === eend
        eend = eend.first
      end
      eend = eend.to_i

      if object.empty?
        object.replace text[start..eend]
      end
    end

    info[:annotation_types] = [Segment] unless info.include? :annotation_types

    Annotated.load(object, info)
  end

  def self.set_tsv_fields(fields, segments)
    tsv_fields = []
    add_types = ! (fields.delete(:no_types) || fields.delete("no_types") || fields.include?(:JSON) || fields.include?("JSON"))
    literal = (fields.delete(:literal) || fields.delete("literal"))
    tsv_fields << "Start" << "End"
    tsv_fields << :annotation_types if add_types
    tsv_fields << :literal if literal

    if fields.any? and not (fields == [:all] or fields == ["all"])
      tsv_fields.concat fields 
    else
      tsv_fields.concat segments.first.annotations if segments.any?
    end
    tsv_fields
    tsv_fields.collect!{|f| f.to_s}
    tsv_fields.delete "offset"
    tsv_fields
  end

  def self.tsv(segments, *fields)
    fields = set_tsv_fields fields, segments
    tsv = TSV.setup({}, :key_field => "ID", :fields => fields, :type => :double)

    segments.each do |segment|
      tsv[segment.id] = self.tsv_values_for_segment(segment, fields)
    end

    tsv
  end

  def self.load_tsv(tsv)
    fields = tsv.fields
    tsv.with_unnamed do
      tsv.collect do |id, values|
        Annotated.load_tsv_values(id, values, fields)
      end
    end
  end

end

