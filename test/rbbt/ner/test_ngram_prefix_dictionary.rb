require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/ngram_prefix_dictionary'
require 'rbbt/util/tmpfile'

class TestNGramPrefixDictionary < Test::Unit::TestCase
  def test_match
    lexicon =<<-EOF
C1;aa;AA;bb b
C2;11;22;3 3;bb
    EOF

    TmpFile.with_file(lexicon) do |file|
      index = NGramPrefixDictionary.new(TSV.new(file, :flat, :sep => ';'), "test")

      matches = index.match(' asdfa dsf asdf aa asdfasdf ')
      assert matches.select{|m| m.code.include? 'C1'}.any?
    end
  end
end

