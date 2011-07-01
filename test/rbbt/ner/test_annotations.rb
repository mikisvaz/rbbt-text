require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/annotations'
require 'rbbt/ner/annotations/named_entity'
require 'rbbt/ner/annotations/transformed'

class TestClass < Test::Unit::TestCase
  def test_info
    a = "test"
    a.extend NamedEntity
    a.type = "type"
    assert a.info.keys.include? "type"
  end

  def test_segment_type
    a = "test"
    a.extend NamedEntity
    assert a.segment_types.include? "NamedEntity"
  end

  def test_align
    text =<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs) are highly aggressive brain tumors of early childhood poorly responding to therapy.
    EOF

    parts = text.split(/\W/)
    Segment.align(text, parts)

    assert_equal "Atypical teratoid/".length, parts.select{|s| s == "rhabdoid"}.first.offset
  end

  def test_sort
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.type = "Gene"

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.type = "Gene"

    assert_equal [gene1,gene2], Segment.sort([gene2,gene1])

  end

  def test_clean_sort
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.type = "Gene"

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.type = "Gene"

    gene3 = "TP53 gene"
    gene3.extend NamedEntity
    gene3.offset = a.index gene3
    gene3.type = "Gene"

    assert_equal [gene3,gene2], Segment.clean_sort([gene2,gene1,gene3])

  end
end

