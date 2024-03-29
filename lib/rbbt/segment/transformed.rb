module Transformed

  def self.transform(text, segments, replacement = nil, &block)

    block = replacement if Proc === replacement

    text.extend Transformed
    text.replace_segments(segments, replacement, &block)

    text
  end
 
  def self.with_transform(text, replace_segments, replacement = nil)

    text.extend Transformed
    text.replace_segments(replace_segments, replacement)

    segments = yield text

    segments = [] unless Array === segments && Segment === segments.first

    text.restore(segments, true)
  end

  attr_accessor :transformed_segments, :transformation_stack

  def shift(segment_o)
    begin_shift = 0
    end_shift = 0

    text_offset = self.respond_to?(:offset)? self.offset.to_i : 0
    @transformed_segments.sort_by{|id, info| info.last}.each{|id,info| 
      pseg_o, diff, utext, pseg_u, index  = info

      pseg_u = ((pseg_u.begin + text_offset)..(pseg_u.last + text_offset))

      case
        # Before
      when segment_o.last + end_shift < pseg_u.begin
        # After
      when (segment_o.begin + begin_shift > pseg_u.last)
        begin_shift += diff
        end_shift += diff
        # Includes
      when (segment_o.begin + begin_shift <= pseg_u.begin and segment_o.last + end_shift >= pseg_u.last)
        end_shift += diff
        # Inside
      when (segment_o.begin + begin_shift >= pseg_u.begin and segment_o.last + end_shift <= pseg_u.last)
        return nil
        # Overlaps start
      when (segment_o.begin + begin_shift <= pseg_u.begin and segment_o.last + end_shift <= pseg_u.last)
        return nil
        # Overlaps end
      when (segment_o.begin + begin_shift >= pseg_u.begin and segment_o.last + end_shift >= pseg_u.last)
        return nil
      else
        raise "Unknown overlaps: #{segment_o.inspect} - #{pseg_u.inspect}"
      end
    }

    [begin_shift, end_shift]
  end

  def replace_segments(segments, replacement = nil, strict = false, &block)
    @transformed_segments ||= {}
    @transformation_stack ||= []
    stack = []

    segments = [segments] unless Array === segments 
    orig_length = self.length

    offset = self.respond_to?(:offset) ? self.offset.to_i : 0

    segments = segments.collect do |s|
      if Segment === s
        s
      elsif String === s
        matches = self.scan(s)
        Segment.align(self, matches)
      end
    end.flatten

    segments = segments.select do |s| 
      shift = shift s.range
      s_offset = s.offset.to_i
      s_offset += shift.first if shift

      s_offset >= offset && 
        s_offset <= offset + self.length - 1 
    end

    Segment.clean_sort(segments).each do |segment|
      next if segment.offset.nil?
      shift = shift segment.range

      next if shift.nil?

      shift_begin, shift_end = shift

      text_offset = self.respond_to?(:offset)? self.offset.to_i : 0

      updated_begin = segment.offset.to_i + shift_begin - text_offset
      updated_end   = segment.range.last + shift_end - text_offset

      updated_range = (updated_begin..updated_end)

      updated_text = self[updated_begin..updated_end]
      if updated_text.nil?
        Log.warn "Range outside of segment: #{self.length} #{segment.range} (#{updated_range})"
        next
      end

      #raise "error '#{segment}' => '#{updated_text}'" if updated_text != segment

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
    when segment.eend < range.begin
      # After
    when segment.offset.to_i > range.end + diff
      segment.offset = segment.offset.to_i - diff
      # Includes
    when (segment.offset.to_i <= range.begin and segment.eend >= range.end + diff)
      segment.replace self[segment.offset.to_i..segment.eend - diff]
    else
      raise "Segment overlaps with transformation: #{Misc.fingerprint(segment)} (#{segment.range} & #{range.begin}..#{range.end + diff})"
    end
  end

  # Restore the sentence from all transformation. Segments that are passed as
  # parameters are restored from transformed space to original space
  def restore(segments = [], first_only = false)
    return segments if @transformation_stack.empty?

    if first_only
      @transformation_stack.pop.reverse.each do |id|
        segment_info = @transformed_segments.delete id
        orig_range, diff, text, range = segment_info 

        new_range = (range.begin..range.last + diff)
        self[new_range] = text
        segments = segments.collect do |segment|
          next segment unless Segment === segment
          begin
            fix_segment(segment, range, diff)
            segment
          rescue
            Log.low "Skipped: " + $!.message
            next
          end
        end.compact if Array === segments
      end
      segments
    else
      while @transformation_stack.any?
        restore(segments, true)
      end
      segments
    end
  end

  #def self.sort(segments)
  #  segments.compact.sort do |a,b|
  #    case
  #    when ((a.nil? && b.nil?) || (a.offset.nil? && b.offset.nil?))
  #      0
  #    when (a.nil? || a.offset.nil?)
  #      -1
  #    when (b.nil? || b.offset.nil?)
  #      +1
  #      # Non-overlap
  #    when (a.end < b.offset.to_i || b.end < a.offset.to_i)
  #      b.offset <=> a.offset
  #      # b includes a
  #    when (a.offset.to_i >= b.offset.to_i && a.end <= b.end)
  #      -1
  #      # b includes a
  #    when (b.offset.to_i >= a.offset.to_i && b.end <= a.end)
  #      +1
  #      # Overlap
  #    when (a.offset.to_i > b.offset.to_i && a.end > b.end || b.offset.to_i > a.offset.to_i && b.end > a.end)
  #      b.length <=> a.length
  #    else
  #      raise "Unexpected case in sort: #{a.range} - #{b.range}"
  #    end
  #  end
  #end

end
