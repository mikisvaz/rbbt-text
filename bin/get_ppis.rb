#!/usr/bin/env ruby

require 'rbbt-util'
require 'rbbt/annotations/corpus'
require 'rbbt/annotations/corpus/pubmed'
require 'rbbt/annotations/relationships/ppi'
require 'rbbt/sources/pubmed'
require 'rbbt/ner/chemical_tagger'

Corpus.define_entity_ner "Compounds", false do |doc|
  @@chemical_tagger ||= ChemicalTagger.new
  @@chemical_tagger.entities(doc.text)
end


corpus = Corpus.new Rbbt.tmp.corpus["PPIS2"].find

docids = corpus.add_pubmed_query("Phospholipidosis", 10000, :abstract)

Misc.benchmark do
  corpus.genes
end

Misc.benchmark do
  corpus.genes
end
