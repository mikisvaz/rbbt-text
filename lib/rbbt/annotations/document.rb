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

  def sentences
    corpus.add_annotations(docid, "Sentence") do 
      NLP.geniass_sentence_splitter(text)
    end
  end

  def sentences_at(pos)
    corpus.annotations_at(docid, pos, "Sentence")
  end

  def genes
    corpus.add_annotations(docid, "Genes") do
      sentences.collect{|sentence|
        Sentence.new(sentence).genes.collect{|gene| 
          gene.pull(sentence.offset)
        }
      }.flatten
    end
  end
end

