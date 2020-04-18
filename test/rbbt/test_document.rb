require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper.rb')
require 'rbbt/document'

class TestDocument < Test::Unit::TestCase

  def test_docid
    text = "This is a document"
    Document.setup(text, "TEST", "test_doc1", nil)

    assert_equal ["TEST", "test_doc1", nil, Misc.digest(text)] * ":", text.docid
  end

end

