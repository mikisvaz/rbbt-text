require 'rbbt/ner/abner'
class Sentence
  attr_accessor :segment
  def docid
    segment.docid
  end

  def initialize(segment)
    @segment = segment
  end

  attr_accessor :genes
  def genes
    return @genes if Array === @genes and not @genes.nil?
    @@abner ||= Abner.new
    @genes = @@abner.entities(segment)
  end
end
