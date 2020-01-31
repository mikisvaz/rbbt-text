require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/nlp/open_nlp/sentence_splitter'
require 'rbbt/ner/segment'

$text=<<-EOF
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
This is a sentence.    
A funky character ™ in a sentence.
This is a sentence.    
This is a 
sentence. This is
another sentence. 
    EOF

    iii OpenNLP.sentence_split_detector.sentDetect(text)
    assert_equal 5, OpenNLP.sentence_split_detector.sentDetect(text).length

    assert_equal 5, OpenNLP.sentence_splitter(text).length
    assert_equal "This is a \nsentence.", OpenNLP.sentence_splitter(text)[3]
  end

  def _test_text_sentences
    Misc.benchmark(100) do
      OpenNLP.sentence_splitter($text).include? "Our
findings highlight the role of SMARCA4 in the pathogenesis of SMARCB1-positive
AT/RT and the usefulness of antibodies directed against SMARCA4 in this
diagnostic setting."
    end
  end
end
 
