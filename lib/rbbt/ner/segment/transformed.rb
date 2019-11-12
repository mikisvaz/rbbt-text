require 'rbbt/util/misc'
require 'rbbt/ner/segment'

module Transformed

  def self.transform(text, segments, replacement = nil, &block)

    text.extend Transformed
    text.replace_segments(segments, replacement, &block)

    text
  end
 
  def self.with_transform(text, segments, replacement = nil)

    text.extend Transformed
    text.replace_segments(segments, replacement)

    segments = yield text

    segments = nil unless Array === segments

    text.restore(segments, true)
  end

  attr_accessor :transformed_segments, :transformation_stack
 
  def shift(segment_o)
    begin_shift = 0
    end_shift = 0

    @transformed_segments.sort_by{|id, info| info.last}.each{|id,info| 
      pseg_o, diff = info

      case
        # Before
      when segment_o.last + end_shift < pseg_o.begin
        # After
      when (segment_o.begin + begin_shift > pseg_o.last)
        begin_shift += diff
        end_shift += diff
        # Includes
      when (segment_o.begin + begin_shift <= pseg_o.begin and segment_o.last + end_shift >= pseg_o.last)
        end_shift += diff
        # Inside
      when (segment_o.begin + begin_shift >= pseg_o.begin and segment_o.last + end_shift <= pseg_o.last)
        return nil
        # Overlaps start
      when (segment_o.begin + begin_shift <= pseg_o.begin and segment_o.last + end_shift <= pseg_o.last)
        return nil
        # Overlaps end
      when (segment_o.begin + begin_shift >= pseg_o.begin and segment_o.last + end_shift >= pseg_o.last)
        return nil
     else
        raise "Unknown overlaps: #{segment_o.inspect} - #{pseg_o.inspect}"
      end
    }

    [begin_shift, end_shift]
  end

  def self.sort(segments)
    segments.compact.sort do |a,b|
      case
      when ((a.nil? && b.nil?) || (a.offset.nil? && b.offset.nil?))
        0
      when (a.nil? || a.offset.nil?)
        -1
      when (b.nil? || b.offset.nil?)
        +1
        # Non-overlap
      when (a.end < b.offset.to_i || b.end < a.offset.to_i)
        b.offset <=> a.offset
        # b includes a
      when (a.offset.to_i >= b.offset.to_i && a.end <= b.end)
        -1
        # b includes a
      when (b.offset.to_i >= a.offset.to_i && b.end <= a.end)
        +1
        # Overlap
      when (a.offset.to_i > b.offset.to_i && a.end > b.end || b.offset.to_i > a.offset.to_i && b.end > a.end)
        a.length <=> b.length
      else
        raise "Unexpected case in sort: #{a.range} - #{b.range}"
      end
    end
  end

  def replace_segments(segments, replacement = nil, &block)
    @transformed_segments ||= {}
    @transformation_stack ||= []
    stack = []

    Transformed.sort(segments).each do |segment|
      next if segment.offset.nil?
      shift = shift segment.range

      next if shift.nil?

      shift_begin, shift_end = shift

      text_offset = self.respond_to?(:offset)? self.offset.to_i : 0
      updated_begin = segment.offset.to_i + shift_begin - text_offset
      updated_end   = segment.range.last + shift_end - text_offset

      updated_range = (updated_begin..updated_end)

      updated_text = self[updated_begin..updated_end]

      original_text = segment.dup
      segment.replace updated_text

      case
      when block_given?
        new =  block.call(segment)
      when String === replacement
        new = replacement
      when Proc === replacement
        new = replacement.call(segment)
      end

      diff = new.length - segment.segment_length

      self[updated_begin..updated_end] = new

      @transformed_segments[segment.object_id] = [segment.range, diff, updated_text, updated_range, @transformed_segments.size]

      segment.replace original_text
      stack << segment.object_id
    end
    @transformation_stack << stack
  end

  def fix_segment(segment, range, diff)
    case
      # Before
    when segment.end < range.begin
      # After
    when segment.offset.to_i > range.end + diff
      segment.offset = segment.offset.to_i - diff
      # Includes
    when (segment.offset.to_i <= range.begin and segment.end >= range.end + diff)
      segment.replace self[segment.offset.to_i..segment.end - diff]
    else
      raise "Segment Overlaps"
    end
  end

  # Restore the sentence from all transformation. Segments that are passed as
  # parameters are restored from transformed space to original space
  def restore(segments = [], first_only = false)
    return segments if @transformation_stack.empty?

    if first_only
      @transformation_stack.pop.reverse.each do |id|
        orig_range, diff, text, range = @transformed_segments.delete id

        new_range = (range.begin..range.last + diff)
        self[new_range] = text
        segments.each do |segment|
          next unless Segment === segment
          fix_segment(segment, range, diff)
        end if Array === segments
      end
      segments
    else
      while @transformation_stack.any?
        restore(segments, true)
      end
      segments
    end
  end
end
