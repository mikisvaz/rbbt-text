require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/ner/banner'
require 'test/unit'

class TestBanner < Test::Unit::TestCase

  def test_match
    begin
      ner = Banner.new

      mentions = ner.match(" The P-ITIM-compelled multi-phosphoprotein complex binds to and activates SHP-2, which in turn dephosphorylates SHIP and Shc and probably other substrates.")
      ["SHP - 2", "SHIP", "Shc"].each{|mention| 
        assert(mentions.include? mention)
      }
    rescue
      puts $!.message
      puts $!.backtrace
    end
  end
end
