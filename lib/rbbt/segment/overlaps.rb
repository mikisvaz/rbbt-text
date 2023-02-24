module SegmentRanges
  def pull(offset)
    if self.offset.nil? or offset.nil?
      self.offset = nil
    else
      self.offset += offset 
    end

    self
  end

  def push(offset)
    if self.offset.nil? or offset.nil?
      self.offset = nil
    else
      self.offset -= offset 
    end

    self
  end

  def make_relative(segments, &block)
    if block_given?
      segments.each{|s| s.push offset}
      yield(segments)
      segments.each{|s| s.pull offset}
    else
      segments.each{|s| s.push offset}
    end
  end

  def range_in(container = nil)
    raise "No offset specified" if offset.nil?
    case
    when (Segment === container and not container.offset.nil?)
      ((offset - container.offset)..(self.eend - container.offset))
    when Integer === container
      ((offset - container)..(self.eend - container))
    else
      range
    end
  end

  def includes?(segment)
    (segment.offset.to_i >= self.offset.to_i) and
    (segment.offset.to_i + segment.segment_length.to_i <= self.offset.to_i + self.segment_length.to_i)
  end

  def overlaps?(segment)
    segment.offset.to_i >= self.offset.to_i && segment.offset.to_i <= self.eend || 
    self.offset.to_i >= segment.offset.to_i && self.offset.to_i <= segment.eend
  end

  def overlaps(segments)
    segments.select{|s| self.overlaps?(s) }
  end

  def self.collisions(main, secondary)
    secondary.select do |ss|
      main.select{|ms| ms.overlaps? ss }.any?
    end
  end
end

module Segment
  include SegmentRanges
end

module SegID
  include SegmentRanges
end
