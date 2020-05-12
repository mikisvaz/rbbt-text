require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/document'
require 'rbbt/document/corpus'
require 'rbbt/segment'
require 'rbbt/segment/annotation'

class TestAnnotation < Test::Unit::TestCase
  def test_annotation
    text = "This is a document"
    Document.setup(text, "TEST", "test_doc1", nil)

    segment = Segment.setup("is", :offset => text.index("is"), :docid => text.docid)
    annotation = SegmentAnnotation.setup(segment, :type => :verb)

    assert_equal 'verb', annotation.annotid.split(":")[5]

    annotation = SegmentAnnotation.setup(segment.segid, :type => :verb)
    assert_equal 'verb', annotation.annotid.split(":")[5]
  end

  def test_annotid
    text = "This is a document"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = Document::Corpus.setup({})

    corpus.add_document(text)

    segment = Segment.setup("is", :offset => text.index("is"), :docid => text.docid)
    annotation = SegmentAnnotation.setup(segment, :type => :verb)

    annotid = annotation.annotid(corpus)

    assert_equal 'verb', annotid.type
    assert_equal 'verb', annotid.annotation.type
    assert_equal 'is', annotid.annotation
  end
end

