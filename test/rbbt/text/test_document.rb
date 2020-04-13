require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/text/document'
require 'rbbt/text/corpus/sources/pmid'

class TestDocument < Test::Unit::TestCase
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

  def test_title_and_text
    document = Document.setup('PMID:32272262')

    assert document.text.downcase.include?("covid")
    assert_equal "High-resolution Chest CT Features and Clinical Characteristics of Patients Infected with COVID-19 in Jiangsu, China.", document.title
  end

  def test_full_text
    document = Document.setup('PMID:4304705')
    assert document.text.length < document.full_text.length
  end

  def test_words
    document = Document.setup('PMID:32272262')
    words = document.entities :words
    assert words.first.respond_to?(:offset)
  end

  def test_genes
    text = "This is a mention to TP53, a gene that should be found"
    document = Document.setup(Document.corpus.add_document(text, "TEST"))
    genes = document.entities :genes

    assert_equal "TP53", genes.first
    assert genes.first.respond_to?(:offset)

    text = "This is a mention to TP53, a gene that should be found"
    document = Document.setup(Document.corpus.add_document(text, "TEST"))
    genes = document.entities :genes

    assert_equal "TP53", genes.first
    assert genes.first.respond_to?(:offset)
  end
end

