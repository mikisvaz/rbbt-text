require File.join(File.expand_path(File.dirname(__FILE__)), '../../../..', 'test_helper.rb')
require 'rbbt/text/document'
require 'rbbt/text/corpus'
require 'rbbt/text/corpus/sources/pmid'

class TestCorpusPMID < Test::Unit::TestCase
  def setup
    Log.severity = 0
    Document.corpus = Corpus.new Rbbt.tmp.test.document_corpus

    Corpus::Document.define :words do
      words = self.text.split(" ")
      Segment.align(self.text, words)
    end

    Corpus::Document.define :genes do
      require 'rbbt/ner/banner'
      Banner.new.match(self.text)
    end

    Corpus::Document.persist_in_global_tsv("genes")
    Corpus::Document.persist_in_global_tsv(:words)
  end

  def test_query
    docids = Document.corpus.add_pubmed_query("SARS-Cov-2", 2000, :abstract)

    docids.each do |docid|
      iif Document.corpus.docid(docid).text
    end
  end
end

