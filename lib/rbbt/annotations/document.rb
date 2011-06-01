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
    corpus.annotations_at(docid, pos, type)
  end

  def sentences
    corpus.add_annotations(docid, "Sentence") do 
      NLP.geniass_sentence_splitter(text)
    end
  end

  def sentences_at(pos)
    annotations_at(pos, "Sentence")
  end
end

