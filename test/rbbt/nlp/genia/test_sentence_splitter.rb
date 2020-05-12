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

    iii NLP.geniass_sentence_splitter(text)
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

    assert_equal "This is a broken\nsentence.", NLP.geniass_sentence_splitter_extension(text)[2].strip
  end
end

