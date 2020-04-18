require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/document'
require 'rbbt/document/corpus'
require 'rbbt/segment'
require 'rbbt/segment/range_index'

class TestRangeIndex < Test::Unit::TestCase
  def test_segment_index
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = {}
    corpus.extend Document::Corpus

    corpus.add_document(text)

    gene1 = "TP53"
    gene1.extend Segment
    gene1.offset = text.index gene1
    gene1.docid = text.docid

    gene2 = "CDK5R1"
    gene2.extend Segment
    gene2.offset = text.index gene2
    gene2.docid = text.docid

    gene3 = "TP53 gene"
    gene3.extend Segment
    gene3.offset = text.index gene1
    gene3.docid = text.docid

    index = Segment::RangeIndex.index([gene1, gene2, gene3], corpus)
    assert_equal "CDK5R1", index[gene2.offset + 1].segment.first

    TmpFile.with_file do |fwt|
      index = Segment::RangeIndex.index([gene1, gene2, gene3], corpus, fwt)
      assert_equal %w(CDK5R1), index[gene2.offset + 1].segment
      index = Segment::RangeIndex.index([gene1, gene2, gene3], corpus, fwt)
      assert_equal %w(CDK5R1), index[gene2.offset + 1].segment
    end
  end
end

