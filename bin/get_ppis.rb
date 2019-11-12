#!/usr/bin/env ruby

require 'rbbt-util'
require 'rbbt/corpus/corpus'
require 'rbbt/corpus/sources/pubmed'
#require 'rbbt/annotations/relationships/ppi'
require 'rbbt/sources/pubmed'
#require 'rbbt/ner/annotations'
require 'rbbt/ner/token_trieNER'
#require 'rbbt/ner/annotations/transformed'
require 'rbbt/ner/chemical_tagger'

Corpus.define_entity_ner "Compounds", false do |doc|
  @@chemical_tagger ||= ChemicalTagger.new
  @@chemical_tagger.entities(doc.text)
end

Corpus.define_entity_ner "Diseases", false do |doc|
  if ! defined? @@tokenizer
    @@tokenizer = TokenTrieNER.new [], :longest_match => true
    @@tokenizer.merge TSV.new(Rbbt.share.databases.COSTART.COSTART, :native => 0, :extra => 0, :flatten => true), :COSTART 
    @@tokenizer.merge TSV.new(Rbbt.share.databases.CTCAE.CTCAE, :native => 0, :extra => 1, :flatten => true), :CTCAE
    @@tokenizer.merge Rbbt.share.databases.Polysearch.disease, :disease
  end
  @@tokenizer.entities(doc.text)
end

corpus = Corpus.new Rbbt.tmp.corpus["PPIS2"].find

docids = corpus.add_pubmed_query("Cancer", 5000, :abstract)

Misc.profile do
  docids[0..100].each do |docid|
    puts "ARTICLE: #{ docid }"
    doc = corpus.docid(docid)
    diseases = doc.produce_diseases
    #puts "Diseases: #{diseases.collect{|g| [g,g.id,g.offset] * ":"} * ", "}"
  #sentences = doc.sentences
  #diseases_index = Segment.index(diseases)
  #sentences.each do |sentence|
  #  diseases_in_sentence = diseases_index[sentence.range]
  #  next if diseases_in_sentence.empty?
  #  Transformed.transform(sentence, sentence.make_relative(diseases_in_sentence.dup)) do |entity|
  #    entity.html
  #  end
  #  puts "---#{[sentence.id, sentence.offset] * ":"}"
  #  puts sentence
  #  puts "Diseases: #{diseases_in_sentence.collect{|g| [g,g.id,g.offset] * ":"} * ", "}"
  #  sentence.restore
  #end
  end
end
