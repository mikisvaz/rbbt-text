require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/corpus/document'
require 'test/unit'


class Document
  define :sentences do 
    require 'rbbt/nlp/nlp'
    NLP.geniass_sentence_splitter(text)
  end

  define :tokens do
    require 'rbbt/ner/annotations/token'
    Token.tokenize(text)
  end
  
  persist :sentences
  persist :tokens
end

class TestDocument < Test::Unit::TestCase

  def test_annotations

    text =<<-EOF
This is a 
sentence. This is
another sentence.
    EOF

    doc = Document.new
    doc.text = text

    assert_equal 2, doc.sentences.length 
    assert_equal 10, doc.tokens.length 
  end

  def test_annotation_load
    text =<<-EOF
This is a 
sentence. This is
another sentence.
    EOF

    doc = Document.new
    doc.text = text * 10

    sentence = doc.sentences.last
    doc.load_into sentence, :tokens 
    assert_equal 5, sentence.tokens.length
    assert_equal "another", sentence.tokens[2]
    assert_equal sentence.offset + 0, sentence.tokens[0].offset
  end

  def test_annotation_persistence
    text =<<-EOF
This is a 
sentence. This is
another sentence. 
    EOF

    TmpFile.with_file do |dir|
      FileUtils.mkdir_p dir

      doc = Document.new(dir)
      doc.text = text * 10
      doc.sentences

      doc = Document.new(dir)
      doc.text = text * 10

      sentence = doc.sentences.last
      doc.load_into sentence, :tokens 
      assert_equal 5, sentence.tokens.length
      assert_equal "another", sentence.tokens[2]
      assert_equal sentence.offset + 0, sentence.tokens[0].offset
    end
  end

  def test_range_persistence
    text =<<-EOF
This is a 
sentence. This is
another sentence. 
    EOF

    TmpFile.with_file do |dir|
      FileUtils.mkdir_p dir

      doc = Document.new(dir)
      doc.text = text * 10

      sentence = doc.sentences.last
      Misc.benchmark(100) do
        doc.load_into sentence, :tokens, :persist => true
        assert_equal 5, sentence.tokens.length
        assert_equal "another", sentence.tokens[2]
        assert_equal sentence.offset + 0, sentence.tokens[0].offset
        assert_equal sentence.offset + 5, sentence.tokens[1].offset
      end
    end
 
  end
end


