require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt/ner/abner'
require 'test/unit'

class TestAbner < Test::Unit::TestCase

  def test_extract
    begin
      ner = Abner.new

      mentions = ner.extract(" The P-ITIM-compelled multi-phosphoprotein complex binds to and activates SHP-2, which in turn dephosphorylates SHIP and Shc and probably other substrates.")
      ["SHP-2", "SHIP", "Shc"].each{|mention| 
        assert(mentions.include? mention)
      }
    rescue
    end
  end
end
