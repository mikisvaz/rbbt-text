require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/nlp/genia/sentence_splitter'

class TestNLP < Test::Unit::TestCase
  def test_sentences
    text =<<-EOF
This is a sentence.    
A funky character ™ in a sentence.
This is a sentence.    
This is a 
sentence. This is
another sentence. 
    EOF

    assert_equal "This is a \nsentence.", NLP.geniass_sentence_splitter(text)[3]
  end

end

