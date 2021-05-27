require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/segment'
require 'rbbt/segment/named_entity'

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
    NamedEntity.setup a, 10, "TEST:doc1:test_type:hash", "NamedEntity", "TYPE", "CODE", "SCORE"
    assert_equal 10, a.offset
    assert_equal "NamedEntity", a.type
    assert_equal "TYPE", a.entity_type
    assert_equal "SCORE", a.score
  end

  def test_tsv
    a = "test"
    NamedEntity.setup a, 10, "DocID", "TYPE", "CODE", "SCORE"
    ppp Annotated.tsv([a,a])
    assert Annotated.tsv([a]).fields.include? "code"
    assert Annotated.tsv([a], nil).fields.include? "code"
    assert Annotated.tsv([a], :all).fields.include? "code"
    assert Annotated.tsv([a], :all).fields.include? "literal"
  end

  def __test_segment_brat
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.entity_type = "Gene"

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.entity_type = "Gene"

    gene3 = "TP53 gene"
    gene3.extend NamedEntity
    gene3.offset = a.index gene3
    gene3.entity_type = "Gene"

    segments = [gene1, gene2, gene3]
    assert segments.collect{|s| s.to_brat}.include? "Gene 27 35"

  end
end
