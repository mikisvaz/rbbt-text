require 'rbbt/annotations/entities/genes'

Corpus.define_entity_ner("PPI:Trigger Term", true, :trigger_terms) do |sentence|
  @@all_trigger_terms ||= Rbbt.share.wordlists.trigger_terms.tsv(:single, :fields => "Trigger_stemmed", :header_hash => "").values
  tokens = Token.tokenize(sentence.segment).collect{|token| token.replace token.stem}
  tokens.select{|t| @@all_trigger_terms.include? t}.collect{|token| text = Segment.annotate(token.original, token.offset)}
end

Corpus.define_entity_ner("PPI", false) do |doc|
  doc.trigger_terms
  doc.genes
  doc.sentences.select{|sentence|
    not sentence.empty? and
    doc.annotations_at(sentence.range, "Genes").length >= 2  and
    doc.annotations_at(sentence.range, "PPI:Trigger Term").any?
  }.collect{|sentence| 
    interactors = doc.annotations_at(sentence.range, "Genes").uniq
    trigger_terms = doc.annotations_at(sentence.range, "PPI:Trigger Term").uniq
    PPI.annotate(sentence.dup, sentence.offset, interactors, trigger_terms)
  }

end



