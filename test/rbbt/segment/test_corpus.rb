require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/document'
require 'rbbt/document/corpus'
require 'rbbt/segment'
require 'rbbt/segment/corpus'

class TestSegmentCorpus < Test::Unit::TestCase
  def test_corpus
    text = "This is a document"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = {}
    corpus.extend Document::Corpus

    corpus.add_document(text)

    docid = text.docid(corpus)

    assert_equal docid.document, text
  end

  def test_find
    text = "This is a document"
    Document.setup(text, "TEST", "test_doc1", nil)

    TmpFile.with_file do |path|
      corpus = Persist.open_tokyocabinet(path, true, :single, "BDB")
      corpus.extend Document::Corpus

      corpus.add_document(text)

      assert corpus.prefix("TEST:").include?(text.docid)
    end
  end
end

