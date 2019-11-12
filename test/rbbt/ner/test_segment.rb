require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/segment'

class TestClass < Test::Unit::TestCase
  def _test_info
    a = "test"
    a.extend Segment
    a.offset = 10
    assert a.info.include? :offset
  end

  def _test_sort
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend Segment
    gene1.offset = a.index gene1

    gene2 = "CDK5R1"
    gene2.extend Segment
    gene2.offset = a.index gene2

    assert_equal [gene1,gene2], Segment.sort([gene2,gene1])
  end

  def _test_clean_sort
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend Segment
    gene1.offset = a.index gene1

    gene2 = "CDK5R1"
    gene2.extend Segment
    gene2.offset = a.index gene2

    gene3 = "TP53 gene"
    gene3.extend Segment
    gene3.offset = a.index gene3

    assert_equal [gene3,gene2], Segment.clean_sort([gene2,gene1,gene3])
  end

  def _test_split
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend Segment
    gene1.offset = a.index gene1

    gene2 = "CDK5R1"
    gene2.extend Segment
    gene2.offset = a.index gene2

    gene3 = "TP53 gene"
    gene3.extend Segment
    gene3.offset = a.index gene3

    assert_equal ["This sentence mentions the ", gene3, " and the ", gene2, " protein"], Segment.split(a, [gene2,gene1,gene3])
  end


  def _test_align
    text =<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs) are highly aggressive brain tumors of early childhood poorly responding to therapy.
    EOF

    parts = text.split(/\W/)
    Segment.align(text, parts)

    assert_equal "Atypical teratoid/".length, parts.select{|s| s == "rhabdoid"}.first.offset
  end

  def _test_segment_index
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend Segment
    gene1.offset = a.index gene1

    gene2 = "CDK5R1"
    gene2.extend Segment
    gene2.offset = a.index gene2

    gene3 = "TP53 gene"
    gene3.extend Segment
    gene3.offset = a.index gene3

    index = Segment.index([gene1, gene2, gene3])
    assert_equal %w(CDK5R1), index[gene2.offset + 1]

    TmpFile.with_file do |fwt|
      index = Segment.index([gene1, gene2, gene3], fwt)
      assert_equal %w(CDK5R1), index[gene2.offset + 1]
      index = Segment.index([gene1, gene2, gene3], fwt)
      assert_equal %w(CDK5R1), index[gene2.offset + 1]
    end
  end
end

