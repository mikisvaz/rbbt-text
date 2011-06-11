require 'rbbt/ner/abner'
class Sentence
  attr_accessor :segment
  def docid
    segment.docid
  end

  def initialize(segment)
    @segment = segment
  end

end
