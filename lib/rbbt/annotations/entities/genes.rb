require 'rbbt/ner/rnorm'
require 'rbbt/sources/organism'

class Corpus
  def genes
    find.collect{|document| document.genes}.flatten
  end
end

class Document
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

class Sentence
  attr_accessor :genes
  def genes
    return @genes if Array === @genes 
    @@abner ||= Abner.new
    @genes = @@abner.entities(segment)
  end
end
