#!/usr/bin/env ruby

require 'rbbt-util'
require 'rbbt/annotations/corpus'
require 'rbbt/annotations/corpus/pubmed'
require 'rbbt/annotations/relationships/ppi'
require 'rbbt/sources/pubmed'
require 'rbbt/ner/annotations'
require 'rbbt/ner/annotations/transformed'
require 'rbbt/ner/chemical_tagger'

Corpus.define_entity_ner "Compounds", false do |doc|
  @@chemical_tagger ||= ChemicalTagger.new
  @@chemical_tagger.entities(doc.text)
end

corpus = Corpus.new Rbbt.tmp.corpus["PPIS2"].find

docids = corpus.add_pubmed_query("Cancer", 1000, :abstract)

  docids.each do |docid|
    puts "ARTICLE: #{ docid }"
    doc = corpus.docid(docid)
    genes = doc.genes
    puts "Genes: #{genes.collect{|g| [g,g.id,g.offset] * ":"} * ", "}"
    sentences = doc.sentences
    genes_index = Segment.index(genes)
    sentences.each do |sentence|
      genes_in_sentence = genes_index[sentence.range]
      next if genes_in_sentence.empty?
      Transformed.transform(sentence, sentence.make_relative(genes_in_sentence.dup)) do |entity|
        entity.html
      end
      puts "---#{[sentence.id, sentence.offset] * ":"}"
      puts sentence
      puts "Genes: #{genes_in_sentence.collect{|g| [g,g.id,g.offset] * ":"} * ", "}"
      sentence.restore
    end
  end
