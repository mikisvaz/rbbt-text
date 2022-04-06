require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/ner/rnorm'

class TestRNorm < Test::Unit::TestCase
  def test_evaluate
    t = Tokenizer.new
    assert t.evaluate("PDGFRA","PDGFRalpha") > 0
    iii t.evaluate("JUNB","JunB")
  end
end

