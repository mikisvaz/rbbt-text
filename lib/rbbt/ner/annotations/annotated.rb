require 'rbbt/ner/annotations'
module Annotated
  attr_accessor :annotations
  def self.annotate(string, annotations = nil)
    string.extend Annotated
    string.annotations = annotations || []
    string
  end

  def split(skip_segments = false)
    Segment.split(self, @annotations, skip_segments)
  end
end


