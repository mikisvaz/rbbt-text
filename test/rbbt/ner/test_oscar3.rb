require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt/ner/oscar3'
require 'rbbt/util/tmpfile'
require 'test/unit'

class TestOSCAR3 < Test::Unit::TestCase


  def test_match
    begin
      ner = OSCAR3.new
      str  = "Alternatively, rearrangement of O-(ω-haloalkyl)esters 34 of 2-carboethoxy-N-hydroxypyridine-2-selone affords azonianaphthalenium halides 37 in 79% yield"

      mentions = ner.match(str, "CM", false)
      good_mentions = ["2-carboethoxy-N-hydroxypyridine-2-selone", "O-(ω-haloalkyl)esters"]

      good_mentions.each{|mention| 
        assert(mentions.include? mention)
      }
    rescue
      puts $!.message
      puts $!.backtrace
    end
  end

  def test_ranges
    begin
      ner = OSCAR3.new
      str =<<-EOF 
This sentence talks about 2-carboethoxy-N-hydroxypyridine-2-selone.
This sentence talks about 2-carboethoxy-N-hydroxypyridine-2-selone.
This sentence talks about 2-carboethoxy-N-hydroxypyridine-2-selone.
This sentence talks about 2-carboethoxy-N-hydroxypyridine-2-selone.
This otherone talks about O-(ω-haloalkyl)esters.
This otherone talks about O-(ω-haloalkyl)esters.
This otherone talks about O-(ω-haloalkyl)esters.

This otherone talks about O-(ω-haloalkyl)esters.
This otherone talks about O-(ω-haloalkyl)esters.
      EOF


      mentions = ner.match(str, "CM", false)

      str_original = str.dup
      mentions.each do |mention|
        str[mention.range] = mention
      end

      assert_equal str_original, str

    rescue
      puts $!.message
      puts $!.backtrace
    end
  end

end
