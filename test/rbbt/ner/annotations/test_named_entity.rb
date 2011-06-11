require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/ner/annotations'
require 'rbbt/ner/annotations/named_entity'
require 'rbbt/ner/annotations/transformed'

class TestClass < Test::Unit::TestCase
  def test_info
    a = "test"
    a.extend NamedEntity
    assert a.info.keys.include? "offset"
  end
end
