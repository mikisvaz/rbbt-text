require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/bow/misc'
require 'test/unit'

class TestBase < Test::Unit::TestCase
  def test_url
    assert_not_nil($stopwords)
  end
end
