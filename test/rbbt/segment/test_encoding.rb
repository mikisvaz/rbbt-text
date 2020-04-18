require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/segment/encoding'

class TestEncoding < Test::Unit::TestCase
  def _test_bad_chars
    text = "A funky character ™ in a sentence."

    assert_equal ["™"], Segment.bad_chars(text)
  end

  def test_ascii
    text = "A funky character ™ in a sentence."

    Segment.ascii(text) do 
      assert_equal "A funky character ? in a sentence.",  text
    end

    Segment.ascii(text, "NONASCII") do 
      assert_equal "A funky character NONASCII in a sentence.",  text
    end

    assert_equal "A funky character ™ in a sentence.",  text
  end
end
