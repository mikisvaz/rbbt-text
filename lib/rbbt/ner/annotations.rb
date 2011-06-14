module Segment 
  attr_accessor :offset, :docid, :segment_types

  def self.included(base)
    class << base
      self.module_eval do 
        define_method "extended" do |object|
          object.segment_types ||= []
          object.segment_types << self.to_s
        end
      end
    end
  end

  def self.annotate(string, offset = nil, docid = nil)
    string.extend Segment
    string.offset = offset
    string.docid = docid
    string
  end

  def id
    new = info.dup
    new.delete :docid
    Digest::MD5.hexdigest(Misc.hash2string(new) << self)
  end
 
  SKIP = %w(docid)
  def info
    equal_ascii = "="[0]
    info = {}
    singleton_methods.select{|method| method[-1] == equal_ascii}.
      collect{|m| m[(0..-2)]}.each{|m| info[m] = self.send(m) if self.respond_to?(m) and not SKIP.include? m.to_s}
    info
    info.delete_if{|k,v| v.nil?}
    info
  end

  def self.load(text, start, eend, info, docid = nil)
    string = text[start.to_i..eend.to_i] if start and eend
    string ||= ""
    string.extend Segment

    # add types
    types = info.delete("segment_types")|| info.delete(:segment_types) || []
    types.each do |type| string.extend Misc.string2const(type) end

    # set info data
    info.each do |key,value|
      string.send key + '=', value if string.respond_to? key.to_sym
    end

    string.docid = docid

    string
  end


  # {{{ Sorting and splitting

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
          b.length <=> a.length
        end
      end.reverse
    else
      segments.sort_by do |segment| segment.offset || 0 end.reverse
    end
  end

  def self.overlaps(sorted_segments)
    last = 0
    overlaped = []
    sorted_segments.reverse.each do |segment| 
      overlaped << segment if segment.range.begin < last
      last = segment.range.end
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

  def self.split(text, segments, skip_segments = false)
    sorted_segments = clean_sort segments

    chunks      = []
    segment_end = 0
    text_offset = 0
    sorted_segments.reverse.each do |segment|
      return chunks if text.nil? or text.empty?
      next if segment.offset.nil?
      offset = segment.offset - text_offset

      # Consider segment offset. Save pre, or skip if overlap
      case
      when offset < 0 # Overlap, skip
        next
      when offset > 0 # Save pre
        chunk = text[0..offset - 1]
        Segment.annotate(chunk, text_offset)
        chunks << chunk
      end

      segment_end = offset + segment.length - 1

      if not skip_segments
        chunk = text[offset..segment_end]
        Segment.annotate(chunk, text_offset + offset)
        chunks << chunk
      end

      text_offset += segment_end + 1
      text = text[segment_end + 1..-1]

    end

    if not text.nil? and text.any?
      chunk = text.dup
      Segment.annotate(chunk, text_offset)
      chunks << chunk
    end

    chunks
  end

  # {{{ Ranges and manipulation

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

  def end
    return nil if offset.nil?
    offset + length - 1
  end

  def range
    raise "No offset specified" if offset.nil?
    (offset..self.end)
  end

  def self.align(text, parts)
    pre_offset = 0
    parts.each do |part|
      offset = text.index part
      raise "Part not found in text: #{ part }" if offset.nil?
      Segment.annotate(part, pre_offset + offset)
      pre_offset += offset
      text = text[offset..-1]
    end
  end

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

  def self.index(segments)
    value_size = 0

    index_data = segments.collect{|segment| 
      next if segment.offset.nil?
      range = segment.range
      value_size = [segment.id.length, value_size].max
      [segment.id, [range.begin, range.end]]
    }.compact

    annotation_index = FixWidthTable.new(:memory, value_size, true)
    annotation_index.add_range index_data

    data = {}
    segments.each do |segment| data[segment.id] = segment end
    Index.new annotation_index, data
  end

end

module Comment
  include Segment
  attr_accessor :comment
  def self.annotate(text, comment = nil)
    text.extend Comment
    text.comment = (comment.nil? ? text : comment)
    text
  end
end
