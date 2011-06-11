require 'rbbt/ner/annotations'

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
