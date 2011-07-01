require 'rbbt/ner/annotations'

module Relationship
  attr_accessor :terms, :segment_types
  include Segment
  def self.annotate(string, offset = nil, terms = nil)
    string.extend PPI
    string.offset = offset unless offset.nil?
    string.terms = terms unless terms.nil?
    string
  end

  def html
    text = <<-EOF
<span class='Relationship'\
>#{ self }</span>
    EOF
    text.chomp
  end

  def html_with_entities(*types)
    annotations.values_at(*types).each do |segments|
    end
  end
end
