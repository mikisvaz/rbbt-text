require File.join(File.expand_path(File.dirname(__FILE__)), '../../../test_helper.rb')
require 'rbbt/annotations/corpus'
require 'rbbt/annotations/corpus/pubmed'
require 'rbbt/annotations/entities/genes'

class TestCorpus < Test::Unit::TestCase
 def test_genes
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid("21611789", :abstract)
    assert corpus.genes.include? "CDKAL1"
  end
end
