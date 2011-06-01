require File.join(File.expand_path(File.dirname(__FILE__)), '../../../test_helper.rb')
require 'rbbt/annotations/corpus'
require 'rbbt/annotations/corpus/pubmed'
require 'rbbt/annotations/entities/genes'
require 'rbbt/annotations/relationships/ppi'

class TestPPI < Test::Unit::TestCase
 def test_ppi
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid("21608079", true)

    assert corpus.ppis.any?

    assert corpus.ppis.select{|ppi| 
      doc = corpus.docid(ppi.docid)
      sentence = doc.sentences_at(ppi.offset).first
      doc.annotations_at(sentence.range, "Genes").include? "p53" 
    }
  end
end
