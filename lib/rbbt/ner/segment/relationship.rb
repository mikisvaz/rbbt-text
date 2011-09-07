require 'rbbt/ner/segment'

module Relationship
  extend Annotation
  include Segment
  self.annotation :terms

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
