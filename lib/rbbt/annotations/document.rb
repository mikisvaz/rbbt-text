require 'rbbt/nlp/nlp'
require 'rbbt/annotations/sentence'
class Document
  attr_accessor :id, :namespace, :type, :hash, :corpus

  def docid
    [namespace, id, type, hash] * ":"
  end

  def text
    corpus.text docid
  end

  def initialize(corpus, namespace, id, type = nil, hash = nil)
    @corpus, @namespace, @id, @type, @hash = corpus, namespace, id, type, hash
  end

  def annotations_at(pos, type)
    corpus.annotations_at(pos, docid, type)
  end

  def segments_at(pos, type)
    corpus.segments_at(pos, docid, type)
  end

end

