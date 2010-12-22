require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt/ner/oscar3'
require 'rbbt/util/tmpfile'
require 'test/unit'

class TestOSCAR3 < Test::Unit::TestCase


  def test_extract
    begin
      ner = OSCAR3.new
      str  = "Alternatively, rearrangement of O-(ω-haloalkyl)esters 34 of 2-carboethoxy-N-hydroxypyridine-2-selone affords azonianaphthalenium halides 37 in 79% yield"

      mentions = ner.extract(str, "CM", false)
      good_mentions = ["2-carboethoxy-N-hydroxypyridine-2-selone", "O-(ω-haloalkyl)esters"]

      good_mentions.each{|mention| 
        assert(mentions.include? mention)
      }
    rescue
      puts $!.message
      puts $!.backtrace
    end
  end
end
