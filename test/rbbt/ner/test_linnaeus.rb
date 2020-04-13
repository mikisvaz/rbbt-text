require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/ner/linnaeus'
require 'test/unit'

class TestLinnaeus < Test::Unit::TestCase

  def test_match
    begin
      mentions = Linnaeus.match("Human HeLa cells and murine models")
      ["Human", "HeLa cells", "murine"].each{|mention| 
        assert(mentions.include? mention)
      }
    rescue
      Log.exception $!
    end
  end
end
