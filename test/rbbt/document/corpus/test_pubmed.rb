require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/document'
require 'rbbt/document/corpus'
require 'rbbt/document/corpus/pubmed'

class TestCorpusPubmed < Test::Unit::TestCase
  def test_add_pmid
    corpus = Document::Corpus.setup({})

    document = corpus.add_pmid("33359141", :abstract).first
    iii document.docid
    title = document.to(:title)
    assert title.include?("COVID-19")
  end
end

