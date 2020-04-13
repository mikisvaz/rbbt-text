$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'test/unit'
require 'rbbt-util'
require 'rbbt/text/corpus'

class Corpus::Document

  define :words do
    text.split(" ")
  end
end

class TestClass < Test::Unit::TestCase
  def test_document
    Log.severity = 0
    text = "This is a test document"

    docid = nil
    TmpFile.with_file do |dir|
      corpus = Corpus.new dir
      docid = corpus.add_document text, :TEST, :test_doc
      document = corpus.docid(docid)
      assert_equal text, document.text

      corpus = Corpus.new dir
      document = corpus.docid(docid)
      assert_equal text, document.text
      document = corpus.find(:TEST, :test_doc).first
      assert_equal text, document.text
    end
  end
end

