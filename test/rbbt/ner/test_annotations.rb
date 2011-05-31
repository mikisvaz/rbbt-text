require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/annotations'

class TestClass < Test::Unit::TestCase
  def test_info
    a = "test"
    a.extend NamedEntity
    assert a.info.keys.include? "offset"
  end

  def test_segment_type
    a = "test"
    a.extend NamedEntity
    assert a.segment_types.include? "NamedEntity"
  end

end

