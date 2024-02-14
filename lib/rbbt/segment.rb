require 'rbbt-util'
require 'rbbt/entity'
require 'rbbt/document'

module SegID
  extend Entity
  self.annotation :corpus

  def _parts
    @parts ||= self.split(":")
  end

  def range
    @range ||= Range.new(*_parts[4].split("..").map(&:to_i))
  end

  def docid
    @docid ||= DocID.setup(_parts[0..3] * ":")
  end

  def offset
    range.begin
  end

  def eend
    offset.to_i + length - 1
  end

  def segment_length
    range.end - range.begin + 1
  end

  property :segment => :single do
    docid = self.docid
    document = DocID.setup(docid, :corpus => corpus).document

    text = document[range]

    Segment.setup(text, :docid => docid, :offset => offset)
  end

  property :segid do
    self
  end

end

module Segment
  extend Entity
  self.annotation :offset, :docid 

  def segment_length
    length
  end


  def eend
    offset.to_i + length - 1
  end

  alias end eend

  def range
    (offset.to_i..eend)
  end

  property :segid do |corpus=nil|
    SegID.setup([docid, range] * ":", :corpus => corpus)
  end

  alias id segid

  property :segment do
    self
  end

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
        when (not a.range.include? b.offset.to_i and not b.range.include? a.offset.to_i)
          a.offset.to_i <=> b.offset.to_i
        else
          a.segment_length <=> b.segment_length
        end
      end
    else
      segments.sort_by do |segment| segment.offset.to_i || 0 end.reverse
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

      segment_end = offset + segment.segment_length - 1

      if not skip_segments
        chunk = text[offset..segment_end]
        Segment.setup(chunk, text_offset + offset)
        chunks << chunk
      end

      text_offset += segment_end + 1
      text = text[segment_end + 1..-1]

    end

    if not text.nil? and not text.empty?
      chunk = text.dup
      Segment.setup(chunk, text_offset)
      chunks << chunk
    end

    chunks
  end

  def self.align(text, parts)
    pre_offset = 0
    docid = text.respond_to?(:docid) ? text.docid : nil
    parts.each do |part|
      offset = text.index part
      next if offset.nil?
      Segment.setup(part, pre_offset + offset, docid)
      pre_offset += offset + part.segment_length
      text = text[(offset + part.segment_length)..-1]
    end
  end

  def self.relocate(segment, original, target, pad = 20)
    if segment != target[segment.range]
      start_pad = [pad, segment.offset].min
      end_pad = [pad, original.length - segment.end].min
      start = segment.offset - start_pad
      eend = segment.end + end_pad

      context = original[start..eend].gsub(/\s/,' ')
      target = target.gsub(/\s/, ' ')
      i = target.index context
      raise "Context not found in original text" if i.nil?
      segment.offset = i + start_pad
    end
  end

  def self.index(*args)
    Segment::RangeIndex.index(*args)
  end
end

require 'rbbt/segment/range_index'
require 'rbbt/segment/overlaps'
require 'rbbt/segment/transformed'
require 'rbbt/segment/segmented'
require 'rbbt/segment/encoding'

