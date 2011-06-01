#!/usr/bin/env ruby

require 'rbbt-util'
require 'rbbt/annotations/corpus'
require 'rbbt/annotations/corpus/pubmed'
require 'rbbt/annotations/relationships/ppi'
require 'rbbt/sources/pubmed'

corpus = Corpus.new Rbbt.tmp.corpus["PPIS"]

pmids = PubMed.query("Cancer", 1000)
corpus.add_pmid(pmids, true)

pmids.collect do |pmid|
  corpus.find("pubmed:#{ pmid }")
end.flatten.each do |document|
  ppis = document.ppis

  next if ppis.empty?
  puts "------"
  puts document.docid.sub(/pubmed:(\d+):.*:.*/,'\1')
  ppis.each do |ppi|
    puts ">"
    puts "PPI: #{ ppi }"
    puts "Genes: #{ppi.interactors * ", "}"
    puts "Triggers: #{ppi.trigger_terms * ", "}"
  end
end
