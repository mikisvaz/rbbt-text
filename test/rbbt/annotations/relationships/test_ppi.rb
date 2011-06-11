require File.join(File.expand_path(File.dirname(__FILE__)), '../../../test_helper.rb')
require 'rbbt/annotations/corpus'
require 'rbbt/annotations/corpus/pubmed'
require 'rbbt/annotations/entities/genes'
require 'rbbt/annotations/relationships/ppi'

class TestPPI < Test::Unit::TestCase
 def test_ppi
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid("21608079", :abstract)

    assert corpus.ppi.any?

    corpus.ppi.select{|ppi| 
      doc = corpus.docid(ppi.docid)
      sentence = doc.sentences_at(ppi.offset).first
      next if sentence.nil?
      doc.annotations_at(sentence.range, "Genes").include? "p53" 
    }
  end
end
