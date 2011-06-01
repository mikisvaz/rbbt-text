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

  def self.annotate(string, offset = nil, docid = nil)
    string.extend Segment
    string.offset = offset
    string.docid = docid
    string
  end

  def pull(offset)
    if self.offset.nil? or offset.nil?
      self.offset = nil
    else
      self.offset += offset 
    end

    self
  end

  def end
    return nil if offset.nil?
    offset + length - 1
  end

  def range
    raise "No offset specified" if offset.nil?
    (offset..self.end)
  end

  def info
    equal_ascii = "="[0]
    info = {}
    singleton_methods.select{|method| method[-1] == equal_ascii}.
      collect{|m| m[(0..-2)]}.each{|m| info[m] = self.send(m) if self.respond_to?(m)}
    info
  end

  def id
    new = info.dup
    new.delete :docid
    [docid, Misc.hash2string(new)] * ">"
  end

  
  def self.load(text, start, eend, info)
    string = text[start..eend] if start and eend
    string ||= ""
    string.extend Segment
    types = info.delete("segment_types")|| info.delete(:segment_types) || []
    types.each do |type| string.extend Misc.string2const(type) end

    info.each do |key,value|
      string.send key + '=', value
    end
    string
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

module PPI
  include Segment
  attr_accessor :trigger_terms, :interactors
  def self.annotate(string, offset = nil, interactors = nil, trigger_terms = nil)
    string.extend PPI
    string.offset = offset
    string.trigger_terms = trigger_terms
    string.interactors = interactors
    string
  end
end

module Token
  include Segment
  attr_accessor :original
  def self.annotate(string, offset = nil, original = nil)
    string.extend Token
    string.offset   = offset
    string.original = original || string.dup
    string
  end

  def self.tokenize(text, split_at = /\s|(\(|\)|[-."':,])/, start = 0)

    tokens = []
    while matchdata = text.match(split_at)
      tokens << Token.annotate(matchdata.pre_match, start) unless matchdata.pre_match.empty?
      tokens << Token.annotate(matchdata.captures.first, start + matchdata.begin(1)) if matchdata.captures.any? and not matchdata.captures.first.empty?
      start += matchdata.end(0)
      text = matchdata.post_match
    end
    tokens << Token.annotate(text, start, token) unless text.empty?

    tokens
  end
end

