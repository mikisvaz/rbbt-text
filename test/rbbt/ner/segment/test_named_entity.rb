require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/ner/segment'
require 'rbbt/ner/segment/named_entity'

class TestClass < Test::Unit::TestCase
  def test_info
    a = "test"
    NamedEntity.setup a
    assert(! a.info.keys.include?(:code))
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
end
