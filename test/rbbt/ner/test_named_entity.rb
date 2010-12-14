require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt/ner/named_entity'
require 'test/unit'

class TestNamedEntity < Test::Unit::TestCase

  def test_annotate
    str = "CDK5"
    NamedEntity.annotate str, :gene, 0.9

    assert String === str
    assert_equal "CDK5", str
    assert_equal :gene, str.type
    assert_equal 0.9, str.score
  end
end
