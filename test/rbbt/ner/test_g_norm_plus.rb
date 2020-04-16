require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/g_norm_plus'

Log.severity = 0
class TestGNormPlus < Test::Unit::TestCase
  def test_match
    text =<<-EOF
We found that TP53 is regulated by MDM2 in Homo sapiens
    EOF

    mentions = GNormPlus.process({:file => text})
    Log.tsv mentions
  end
end

