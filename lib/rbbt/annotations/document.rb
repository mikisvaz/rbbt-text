require 'rbbt/nlp/nlp'
require 'rbbt/annotations/sentence'
class Document
  attr_accessor :id, :namespace, :type, :hash, :corpus

  def docid
    [namespace, id, type, hash] * ":"
  end

  def text
    @text ||= corpus.text docid
  end

  def initialize(corpus, namespace, id, type = nil, hash = nil)
    @corpus, @namespace, @id, @type, @hash = corpus, namespace, id, type, hash
  end

  def load_segment(annotation)
    @corpus.load_segment(text, annotation)
  end

  def segment_for(annotation_id)
    @corpus.segment_for(text, annotation_id)
  end

  def annotation_index(type = nil)
    corpus.annotation_index(docid, type)
  end

  def annotations_at(pos, type)
    annotation_index(type)[pos]
  end

  def segments_at(pos, type = nil)
    corpus.segments_at(pos, docid, type)
  end

  def clean(type = nil)
    annotation_repo.clean(docid, type)
  end

end

