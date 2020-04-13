require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/text/segment'
require 'rbbt/text/segment/named_entity'

class TestClass < Test::Unit::TestCase
  def test_info
    a = ["test"]
    NamedEntity.setup a
    assert(a.info[:code].nil?)
    a.code = 10
    a.offset = 100
    assert a.info.include? :code
    assert a.info.include? :offset
  end

  def test_all_args
    a = "test"
    NamedEntity.setup a, 10, "TYPE", "CODE", "SCORE"
    assert_equal 10, a.offset
  end

  def test_tsv
    a = "test"
    NamedEntity.setup a, 10, "TYPE", "CODE", "SCORE"
    assert Segment.tsv([a]).fields.include? "code"
    assert Segment.tsv([a], nil).fields.include? "code"
    assert Segment.tsv([a], "literal").fields.include? "code"
  end

  def test_segment_brat
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

    segments = [gene1, gene2, gene3]
    assert segments.collect{|s| s.to_brat}.include? "Gene 27 35"

  end
end
