require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/nlp/nlp'

text=<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs) are highly aggressive brain tumors
of early childhood poorly responding to therapy. The majority of cases show
inactivation of SMARCB1 (INI1, hSNF5, BAF47), a core member of the adenosine
triphosphate (ATP)-dependent SWI/SNF chromatin-remodeling complex. We here
report the case of a supratentorial AT/RT in a 9-month-old boy, which showed
retained SMARCB1 staining on immunohistochemistry and lacked genetic
alterations of SMARCB1. Instead, the tumor showed loss of protein expression of
another SWI/SNF chromatin-remodeling complex member, the ATPase subunit SMARCA4
(BRG1) due to a homozygous SMARCA4 mutation [c.2032C>T (p.Q678X)].  Our
findings highlight the role of SMARCA4 in the pathogenesis of SMARCB1-positive
AT/RT and the usefulness of antibodies directed against SMARCA4 in this
diagnostic setting.
  EOF

class TestClass < Test::Unit::TestCase

  def test_sentences
    text =<<-EOF
This is a 
sentence. This is
another sentence.
    EOF

    assert_equal 2, NLP.geniass_sentence_splitter(text).length
    assert_equal "This is a \nsentence. ", NLP.geniass_sentence_splitter(text).first
  end

  def test_gdep_parse_sentences
    text =<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs)
are highly aggressive brain
tumors of early childhood poorly 
responding to therapy.
    EOF

    NLP.gdep_parse_sentences([text, text]).zip([text,text]).each do |segment_list, sentence|
      segment_list.each do |segment|
        assert_equal sentence[segment.range], segment
      end
    end
  end

  def test_gdep_chunks
    text =<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs)
are highly aggressive brain
tumors of early childhood poorly 
responding to therapy.
    EOF

    NLP.gdep_parse_sentences([text, text]).zip([text,text]).each do |segment_list, sentence|
      chunk_list = NLP.gdep_chunks(sentence, segment_list)
      chunk_list.each do |segment|
        assert_equal sentence[segment.range], segment
      end

      assert chunk_list.select{|c| c =~ /rhabdoid/}.first.annotations.include? "tumors"
    end
 
  end

  def test_merge_chunks
    text =<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs)
where found to be like highly aggressive brain
tumors of early childhood poorly 
responding to therapy.
    EOF

    NLP.gdep_parse_sentences([text, text]).zip([text,text]).each do |segment_list, sentence|
      chunk_list = NLP.gdep_chunks(sentence, segment_list)
      new_chunk_list = NLP.merge_vp_chunks(chunk_list)
      
      new_chunk_list.each do |segment|
        assert_equal sentence[segment.range], segment
      end

      assert new_chunk_list.select{|c| c.type == "VP"}.first.annotations.include? "found"
      assert new_chunk_list.select{|c| c.type == "VP"}.first.annotations.include? "to"
      assert new_chunk_list.select{|c| c.type == "VP"}.first.annotations.include? "be"
    end
  end
end
 
