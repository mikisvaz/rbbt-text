require 'rbbt/ner/segment'

module SegmentWithDocid 
  extend Annotation

  self.annotation :docid

  def masked?
    self[0..5] == "MASKED"
  end

  def mask
    return self if masked?
    raise "Cannot mask an array of elements, they must be masked individually" if Array === self
    raise "Cannot mask a segment with no docid" if not self.respond_to? :docid or docid.nil?
    raise "Cannot mask a segment with no offset" if offset.nil?
    textual_position = ["MASKED", length] * ":"
    self.replace(textual_position)
    self
  end

  def unmasked_text
    return self unless masked?
    tag, length = self.split(":")
    Document.setup(docid).text[offset.to_i..(offset.to_i+length.to_i-1)]
  end

  def unmask
    return self unless masked?
    self.replace(unmasked_text)
    self
  end

  def str_length
    self.length
  end

  def masked_length
    self.split(":").last.to_i
  end

  def segment_length
    masked? ? masked_length : str_length
  end
end

