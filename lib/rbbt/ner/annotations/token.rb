require 'rbbt/ner/annotations'

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

    tokens << Token.annotate(text, start) unless text.empty?

    tokens
  end
end

