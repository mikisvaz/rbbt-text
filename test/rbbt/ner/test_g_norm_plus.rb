require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/g_norm_plus'

Log.severity = 0
class TestGNormPlus < Test::Unit::TestCase
  def _test_match
    text =<<-EOF

Introduction

We found that TP53 is regulated by MDM2 in Homo 
sapiens
    EOF

    Rbbt::Config.add_entry :java_mem, "16G", :gnp
    mentions = GNormPlus.process({:file => text})

    assert_equal 1, mentions.length
    assert_equal 3, mentions["file"].length
  end

  def test_entities
    text =<<-EOF
We found that TP53 is regulated by MDM2 in Homo sapiens
    EOF

    Rbbt::Config.add_entry :java_mem, "16G", :gnp
    mentions = GNormPlus.entities({:file => text})
    assert mentions["file"].include?("TP53")
    mentions["file"].each do |mention|
      assert_equal mention, text[mention.range].sub("\n", ' ')
    end
  end
end

