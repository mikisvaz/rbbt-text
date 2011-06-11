require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/annotations'
require 'rbbt/ner/annotations/named_entity'
require 'rbbt/ner/annotations/transformed'

class TestClass < Test::Unit::TestCase
  def _test_info
    a = "test"
    a.extend NamedEntity
    assert a.info.keys.include? "offset"
  end

  def _test_segment_type
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
end

