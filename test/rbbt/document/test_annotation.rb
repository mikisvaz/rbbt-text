require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/document'
require 'rbbt/document/corpus'
require 'rbbt/segment'
require 'rbbt/document/annotation'
require 'rbbt/segment/named_entity'
require 'rbbt/ner/abner'

class TestAnnotation < Test::Unit::TestCase
  class CalledOnce < Exception; end
  def setup
    Document.define :words do
      self.split(" ")
    end

    Document.define :lines do
      self.split("\n")
    end

    $called_once = false
    Document.define :persisted_words do
      raise CalledOnce if $called_once
      $called_once = true
      self.split(" ")
    end

    Document.define_multiple :multiple_words do |list|
      list.collect{|doc| doc.words}
    end

    Document.define :ner do
      $called_once = true
      self.split(" ").collect{|e| NamedEntity.setup(e, :code => Misc.digest(e)) }
    end

    Document.define :abner do
      $called_once = true
      Abner.new.match(self)
    end


    Document.persist :ner
  end

  def test_define
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = {}
    Document::Corpus.setup corpus

    corpus.add_document(text)

    assert_equal text[text.words[1].range], text.words[1]
  end

  def test_define_multiple
    text1 = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    text2 = "This is another sentence"
    Document.setup(text1, "TEST", "test_doc1", nil)
    Document.setup(text2, "TEST", "test_doc2", nil)

    corpus = {}
    Document::Corpus.setup corpus

    corpus.add_document(text1)
    corpus.add_document(text2)

    assert_equal 2, Document.setup([text1, text2]).multiple_words.length
    assert_equal text1.split(" "), text1.multiple_words

    #Document.persist :multiple_words, :annotations, :annotation_repo => Rbbt.tmp.test.multiple_words
    #assert_equal 2, Document.setup([text1, text2]).multiple_words.length
    #assert_equal text1.split(" "), text1.multiple_words
  end

  def test_persist
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = {}
    Document::Corpus.setup corpus

    corpus.add_document(text)

    assert_equal "persisted_words", text.persisted_words.first.type

    assert_raise CalledOnce do
      assert_equal text[text.persisted_words[1].range], text.persisted_words[1]
    end

    Log.severity = 0
    Document.persist :persisted_words, :annotations, :file => Rbbt.tmp.test.persisted_words.find(:user)

    $called_once = false
    text.persisted_words
    assert $called_once

    assert_nothing_raised  do
      assert_equal text[text.persisted_words[1].range], text.persisted_words[1]
    end
  end

  def test_persist_annotation_repo
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = {}
    Document::Corpus.setup corpus

    corpus.add_document(text)

    assert_equal "persisted_words", text.persisted_words.first.type

    assert_raise CalledOnce do
      assert_equal text[text.persisted_words[1].range], text.persisted_words[1]
    end

    Log.severity = 0
    Document.persist :persisted_words, :annotations, :annotation_repo => Rbbt.tmp.test.persisted_words_repo.find(:user)

    $called_once = false
    text.persisted_words
    assert $called_once

    assert_nothing_raised  do
      assert_equal text[text.persisted_words[1].range], text.persisted_words[1]
    end
  end

  def test_persist_ner
    text = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Document.setup(text, "TEST", "test_doc1", nil)

    corpus = {}
    Document::Corpus.setup corpus

    corpus.add_document(text)


    text.ner

    $called_once = false
    text.ner

    assert ! $called_once

    assert_equal text.abner.first.docid, text.docid

    assert  text.ner.first.segid.include?("TEST:")
  end

  def test_sentence_words
    text =<<-EOF
This is sentence 1
This is sentence 2
    EOF

    Document.setup(text)

    words = text.words
    numbers = words.select{|w| w =~ /\d/}
    text.lines.each do |sentence|
      Transformed.with_transform(sentence, numbers, "[NUM]") do
        puts sentence
      end
    end
  end
end

