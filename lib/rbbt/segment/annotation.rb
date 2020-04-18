require 'rbbt-util'
require 'rbbt/entity'
require 'rbbt/segment'

module AnnotID
  extend Entity
  self.annotation :corpus

  def _parts
    @parts ||= self.split(":")
  end

  def segid
    @segid ||= _parts[0..4] * ":"
  end

  def type
    @type ||= _parts[5]
  end

  property :annotation do
    segment = SegID.setup(segid, :corpus => corpus).segment

    SegmentAnnotation.setup(segment, :type => type)
  end

  property :annotid do
    self
  end

end

module SegmentAnnotation
  extend Entity
  include Segment
  self.annotation :type

  property :segid do
    case self
    when SegID
      self
    when Segment
      super()
    else
      raise "Unknown object: #{self}"
    end
  end

  property :annotid do |corpus=nil|
    AnnotID.setup([segid, type] * ":", :corpus => corpus)
  end

  alias id annotid

  property :annotation do
    self
  end
end
