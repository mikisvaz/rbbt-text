require 'rbbt/segment'
module Segment
  def self.bad_chars(text)
    segments = []
    text.chars.each_with_index do |c,i|
      if ! c.ascii_only?
        segments << Segment.setup(c, :offset => i)
      end
    end
    segments
  end

  def self.ascii(text, replace = nil, &block)
    bad = bad_chars(text)
    replace = "?" if replace.nil?
    Transformed.with_transform(text, bad, replace, &block)
  end
end
