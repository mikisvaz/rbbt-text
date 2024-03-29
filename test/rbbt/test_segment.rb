require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper.rb')
require 'rbbt/document'
require 'rbbt/document/corpus'
require 'rbbt/segment'

class TestSegment < Test::Unit::TestCase
  def test_segment
    text = "This is a document"
    Document.setup(text, "TEST", "test_doc1", nil)

    segment = Segment.setup("is", :offset => text.index("is"), :docid => text.docid)

    assert_equal text.docid + ":" + segment.offset.to_s + ".." + segment.eend.to_s,  segment.segid
  end

  def test_segid
    text = "This is a document"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = Document::Corpus.setup({})

    corpus.add_document(text)

    segment = Segment.setup("is", :offset => text.index("is"), :docid => text.docid)

    segid = segment.segid(corpus)

    segment = segid.segment
    assert_equal "is", segment
  end

  def test_info
    segment = "test"
    segment.extend Segment
    segment.offset = 10
    assert segment.info.include? :offset
  end

  def test_sort
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = Document::Corpus.setup({})

    corpus.add_document(text)

    gene1 = "TP53"
    gene1.extend Segment
    gene1.offset = text.index gene1
    gene1.docid = text.docid

    gene2 = "CDK5R1"
    gene2.extend Segment
    gene2.offset = text.index gene2
    gene2.docid = text.docid

    assert_equal [gene1,gene2], Segment.sort([gene2,gene1])

    assert_equal [gene1,gene2], Segment.sort([gene2.segid(corpus),gene1.segid(corpus)]).collect{|segid| segid.segment}
  end

  def test_clean_sort
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = Document::Corpus.setup({})

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

    assert_equal [gene1,gene2], Segment.sort([gene2,gene1])

    assert_equal [gene3,gene2], Segment.clean_sort([gene2,gene1,gene3])
  end

  def test_split
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = Document::Corpus.setup({})

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

    assert_equal ["This sentence mentions the ", gene3, " and the ", gene2, " protein"], Segment.split(text, [gene2, gene1, gene3])

    assert_equal ["This sentence mentions the ", gene3, " and the ", gene2, " protein"], Segment.split(text, [gene2, gene1, gene3].collect{|s| s.segid})
  end


  def test_align
    text =<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs) are highly aggressive brain tumors of early childhood poorly responding to therapy.
    EOF

    parts = text.split(/\W/)
    Segment.align(text, parts)

    assert_equal "Atypical teratoid/".length, parts.select{|s| s == "rhabdoid"}.first.offset

    Document.setup(text, "TEST", "test_doc1", nil)

    parts = text.split(/\W/)
    Segment.align(text, parts)

    assert_equal parts.first.docid, text.docid
  end

  def test_align_parts
    text =<<-EOF
aabbccdd
    EOF

    parts = %w(aa bb cc dd)
    Segment.align(text, parts)

    parts.each do |p|
      assert_equal p, text[p.range]
    end
  end


  def test_relocate
    original =<<-EOF
This sentences contains
a mention to gene TP53
This is a followup sentence
    EOF

    target = <<-EOF
    This sentence is added before
This sentences contains a mention to gene TP53
This is a followup sentence
    EOF

    segment = Segment.setup("TP53")
    Segment.align(original, [segment])
    Segment.relocate(segment, original, target)
    assert_equal segment, target[segment.range]
  end

  def test_segment_index
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = Document::Corpus.setup({})

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

    index = Segment.index([gene1, gene2, gene3], corpus)
    assert_equal "CDK5R1", index[gene2.offset + 1].segment.first

    TmpFile.with_file do |fwt|
      index = Segment.index([gene1, gene2, gene3], corpus, fwt)
      assert_equal %w(CDK5R1), index[gene2.offset + 1].segment
      index = Segment.index([gene1, gene2, gene3], corpus, fwt)
      assert_equal %w(CDK5R1), index[gene2.offset + 1].segment
    end

    index = Segment.index([gene1, gene2, gene3].collect{|s| s.segid}, corpus)
    assert_equal "CDK5R1", index[gene2.offset + 1].segment.first

    TmpFile.with_file do |fwt|
      index = Segment.index([gene1, gene2, gene3].collect{|s| s.segid}, corpus, fwt)
      assert_equal %w(CDK5R1), index[gene2.offset + 1].segment
      index = Segment.index([gene1, gene2, gene3].collect{|s| s.segid}, corpus, fwt)
      assert_equal %w(CDK5R1), index[gene2.offset + 1].segment
    end
  end

end

