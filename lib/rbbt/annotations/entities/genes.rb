require 'rbbt/ner/rnorm'
require 'rbbt/sources/organism'
require 'rbbt/annotations/entities'

Corpus.define_entity_ner("Genes", true) do |sentence|
  @@abner ||= Abner.new
  @@abner.entities sentence.segment
end
