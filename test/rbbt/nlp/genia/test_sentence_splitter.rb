require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/nlp/genia/sentence_splitter'

class TestNLP < Test::Unit::TestCase
  def test_sentences
    text =<<-EOF
This is a sentence.    
A funky character ™ in a sentence.
This is a sentence.    
This is a broken
sentence. This is
another broken sentence. 
    EOF

    assert_equal "This is a broken\nsentence.", NLP.geniass_sentence_splitter(text)[2].strip
  end

  def test_sentences_2
    text =<<-EOF
This is a sentence.    
This is a sentence.    
This is a broken
sentence. This is
another broken sentence. 
    EOF

    assert_equal "This is a broken\nsentence.", NLP.geniass_sentence_splitter(text)[2].strip
  end

  def test_sentences_ext
    text =<<-EOF
This is a sentence.    
This is a sentence.    
This is a broken
sentence. This is
another broken sentence. 
    EOF

    Log.with_severity 0 do
      assert_equal "This is a broken\nsentence.", NLP.geniass_sentence_splitter_extension(text)[2].strip
    end
  end

  def test_sentence_cmi
    text =<<-EOF
The COVID-19 infection was reported as the main cause of death and patients with a higher mortality risk were those aged ≥65 years [adjusted HR = 3.40 (95% CI 2.20-5.24)], with a higher disease severity [adjusted HR = 1.87 (95%CI 1.43-2.45)].
    EOF

    iii NLP.geniass_sentence_splitter(text)
  end
end

