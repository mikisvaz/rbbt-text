require 'rbbt/ner/annotations'

module Relationship
  include Segment
  attr_accessor :terms
  def self.annotate(string, offset = nil, terms = nil)
    string.extend PPI
    string.offset = offset unless offset.nil?
    string.terms = terms unless terms.nil?
    string
  end
end
