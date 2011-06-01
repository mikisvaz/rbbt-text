require 'rbbt/annotations/entities/genes'

class Corpus
  def ppis
    find.collect{|document| document.ppis}.flatten
  end
end

class Document
  def trigger_terms
    corpus.add_annotations(docid, "PPI:Trigger Term") do
      sentences.collect{|sentence|
        Sentence.new(sentence).trigger_terms.collect{|trigger| 
          trigger.pull(sentence.offset)
        }
      }.flatten
    end
  end

  def ppis
    self.trigger_terms
    self.genes
    corpus.add_annotations(docid, "PPI") do
      sentences.select{|sentence|
        not sentence.empty? and
        annotations_at(sentence.range, "Genes").length >= 2  and
        annotations_at(sentence.range, "PPI:Trigger Term").any?
      }.collect{|sentence| 
        interactors = annotations_at(sentence.range, "Genes").uniq
        trigger_terms = annotations_at(sentence.range, "PPI:Trigger Term").uniq
        PPI.annotate(sentence.dup, sentence.offset, interactors, trigger_terms)
      }
    end
  end
end

class Sentence
  attr_accessor :trigger_terms
  def trigger_terms
    require 'stemmer'
    require 'rbbt/bow/misc'

    return @trigger_terms if Array === @trigger_terms
    tokens = Token.tokenize(self.segment).collect{|token| token.replace token.stem}
    @@all_trigger_terms ||= Rbbt.share.wordlists.trigger_terms.tsv(:single, :fields => "Trigger_stemmed", :header_hash => "").values
    tokens.select{|t| @@all_trigger_terms.include? t}.collect{|token| text = Segment.annotate(token.original, token.offset)}
  end
end
