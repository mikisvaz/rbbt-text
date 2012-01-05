require 'rbbt/annotations'
require 'rbbt/ner/segment'

module Token
  attr_accessor :offset, :original
  
  def self.all_annotations
    [:offset, :original]
  end

  def self.setup(text, start, original = nil)
    text.extend Token
    text.offset = start
    text.original = original
    text
  end
  
  def info
    {:original => original, :offset => offset}
  end

  def id
    Misc.hash2md5 info.merge :self => self
  end

  def end
    offset + self.length - 1
  end

  def range
    (offset..self.end)
  end

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

