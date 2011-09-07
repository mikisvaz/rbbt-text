require 'rbbt/ner/segment'
module Transformed
  attr_accessor :transformation_offset_differences, :transformation_original

  def self.transform(text, segments, replacement = nil, &block)
    require 'rbbt/util/misc'

    text.extend Transformed
    text.replace(segments, replacement, &block)

    text
  end
 
  def self.with_transform(text, segments, replacement)
    require 'rbbt/util/misc'

    text.extend Transformed
    text.replace(segments, replacement)

    segments = yield text

    segments = nil unless Array === segments

    text.restore(segments, true)
  end

  def transform_pos(pos)
    return pos if transformation_offset_differences.nil?
    # tranformation_offset_differences are assumed to be sorted in reverse
    # order
    transformation_offset_differences.reverse.each do |trans_diff|
      acc = 0
      trans_diff.reverse.each do |offset, diff, orig_length, trans_length|
        break if offset >=  pos
        acc += diff 
      end
      pos = pos - acc 
    end

    pos
  end

  def transform_range(range)
    (transform_pos(range.begin)..transform_pos(range.end))
  end

  def transformed_set(pos, value)
    transformed_pos = case
                when Range === pos
                  transform_range(pos)
                when Integer === pos
                  transform_pos(pos)
                else
                  raise "Text position not understood '#{pos.inspect}'. Not Range or Integer"
                end

    self[transformed_pos] = value
  end

  def transformed_get(pos)
    transformed_pos = case
                when Range === pos
                  transform_range(pos)
                when Integer === pos
                  transform_pos(pos)
                else
                  raise "Text position not understood '#{pos.inspect}'. Not Range or Integer"
                end

    self[transformed_pos]
  end

  def conflict?(segment_range)
    return false if @transformation_offset_differences.nil? or @transformation_offset_differences.empty?
    transformation_offset_difference = @transformation_offset_differences.last

    transformation_offset_difference.each do |info|
      offset, diff, orig_length, trans_length = info
      return true if segment_range.begin > offset and segment_range.begin < offset + trans_length or
      segment_range.end   > offset and segment_range.end   < offset + trans_length
    end

    return false
  end

  def replace(segments, replacement = nil, &block)
    replacement ||= block
    raise "No replacement given" if replacement.nil?
    transformation_offset_differences = []
    transformation_original = []

    Segment.clean_sort(segments).reverse.each do |segment|
      untransformed_segment_range_here= segment.range_in(self)
      transformed_segment_range  = self.transform_range(untransformed_segment_range_here)
      next if conflict?(transformed_segment_range)

      text_before_transform = self[transformed_segment_range]

      case
      when String === replacement
        transformed_text = replacement
      when Proc === replacement

        # Prepare segment with new text
        save_segment_text = segment.dup
        save_offset = segment.offset
        segment.replace text_before_transform
        segment.offset = transformed_segment_range.begin

        transformed_text = replacement.call segment

        # Restore segment with original text
        segment.replace save_segment_text
        segment.offset = save_offset
      else
        raise "Replacemente not String nor Proc"
      end
      diff = segment.length - transformed_text.length
      self[transformed_segment_range] = transformed_text

      transformation_offset_differences << [untransformed_segment_range_here.begin, diff, text_before_transform.length, transformed_text.length]
      transformation_original << text_before_transform
    end

    @transformation_offset_differences ||= []
    @transformation_offset_differences << transformation_offset_differences
    @transformation_original ||= []
    @transformation_original << transformation_original
  end

  def restore(segments = nil, first_only = false)
    stop = false
    while self.transformation_offset_differences.any? and not stop
      transformation_offset_differences = self.transformation_offset_differences.pop
      transformation_original           = self.transformation_original.pop

      ranges = transformation_offset_differences.collect do |offset,diff,orig_length,rep_length|
        (offset..(offset + rep_length - 1))
      end

      ranges.zip(transformation_original).reverse.each do |range,text|
        self.transformed_set(range, text)
      end

      stop = true if first_only

      next if segments.nil?

      segment_ranges = segments.each do |segment|
        r = segment.range

        s = r.begin
        e = r.end
        sdiff = 0
        ediff = 0
        transformation_offset_differences.reverse.each do |offset,diff,orig_length,rep_length|
          sdiff += diff if offset < s
          ediff += diff if offset + rep_length - 1 < e
        end

        segment.offset = s + sdiff
        segment.replace self[(s+sdiff)..(e + ediff)]
      end
    end

    segments
  end
end


