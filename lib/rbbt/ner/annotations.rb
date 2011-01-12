module Segment 
  attr_accessor :offset

  def self.sort(segments)
    segments.sort_by do |segment| segment.offset || 0 end
  end

  def self.split(text, segments)
    sorted_segments = sort segments

    chunks      = []
    segment_end = 0
    text_offset = 0
    sorted_segments.each do |segment|
      next if segment.offset.nil?

      offset = segment.offset - text_offset
      case
      when offset < 0
        next
      when offset > 0
        chunk = text[0..offset - 1]
        Segment.annotate(chunk, text_offset)
        chunks << chunk
      end

      segment_end = offset + segment.length - 1

      chunk = text[offset..segment_end]
      Segment.annotate(chunk, text_offset + offset)
      chunks << chunk

      text = text[(segment_end + 1)..-1]
      text_offset = segment_end + 1
    end

    if text.any?
      chunk = text
      Segment.annotate(chunk, text_offset)
      chunks << chunk
    end
  end

  def self.annotate(string, offset = nil)
    string.extend Segment
    string.offset = offset
    string
  end

  def range
    (offset..offset + length - 1)
  end
end

module Annotated
  attr_accessor :annotations
  def self.annotate(string)
    string.extend Annotated
    string.annotations = []
    string
  end

  def split
    Segment.split(self, @annotations)
  end
end

module NamedEntity 
  include Segment
  attr_accessor :type, :code, :score

  def self.annotate(string, offset = nil, type = nil, code = nil, score = nil)
    string.extend NamedEntity
    string.offset = offset
    string.type  = type
    string.code  = code
    string.score = score
    string
  end
end

module Token
  include Segment
  attr_accessor :original
  def self.annotate(string, offset = nil, original = nil)
    string.extend Token
    string.offset   = offset
    string.original = original
    string
  end
end

