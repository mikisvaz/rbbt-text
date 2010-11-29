require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'rbbt/bow/misc'
require 'test/unit'

class TestBase < Test::Unit::TestCase
  def test_url
    assert_not_nil($stopwords)
  end
end
