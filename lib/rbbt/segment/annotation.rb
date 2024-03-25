require 'rbbt-util'
require 'rbbt/segment'
require 'rbbt/entity'

module AnnotID
  extend Entity
  include SegID
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
  include Object::Segment
  self.annotation :type

  def segid
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
    AnnotID.setup([segid, type, Misc.obj2digest(self.info)] * ":", :corpus => corpus)
  end

  alias id annotid

  property :annotation do
    self
  end
end
