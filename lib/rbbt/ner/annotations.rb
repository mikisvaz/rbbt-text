module Segment 
  attr_accessor :offset

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
      segments.sort_by do |segment| segment.offset || 0 end
    end
  end

  def self.split(text, segments)
    sorted_segments = sort segments

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
        Segment.annotate(chunk, text_offset)
        chunks << chunk
      end

      segment_end = offset + segment.length - 1

      chunk = text[offset..segment_end]
      Segment.annotate(chunk, text_offset + offset)
      chunks << chunk

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

  def to_s
    <<-EOF
String: #{ self }
Offset: #{ offset.inspect }
Type: #{type.inspect}
Code: #{code.inspect}
Score: #{score.inspect}
    EOF
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

