require 'rbbt/annotations'
require 'rbbt/text/segment'

module Segmented
  extend Annotation
  self.annotation :segments

  def split_segments(skip_segments = false)
    Segment.split(self, @segments, skip_segments)
  end
end


