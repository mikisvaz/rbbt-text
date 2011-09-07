require 'rbbt/annotations'
require 'rbbt/ner/segment'

module Token
  extend Annotation
  include Segment
  self.annotation :original

  def self.tokenize(text, split_at = /\s|(\(|\)|[-."':,])/, start = 0)

    tokens = []
    while matchdata = text.match(split_at)
      tokens << Token.setup(matchdata.pre_match, start) unless matchdata.pre_match.empty?
      tokens << Token.setup(matchdata.captures.first, start + matchdata.begin(1)) if matchdata.captures.any? and not matchdata.captures.first.empty?
      start += matchdata.end(0)
      text = matchdata.post_match
    end

    tokens << Token.setup(text, start) unless text.empty?

    tokens
  end
end

