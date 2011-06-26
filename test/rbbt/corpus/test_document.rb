require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/corpus/document'
require 'test/unit'

$persistence = TSV.new({})
$tchash_persistence = TCHash.get(Rbbt.tmp.test.document.persistence.find(:user), true, Persistence::TSV::TSVSerializer)
$global_persistence = TSV.new({}, :key => "ID", :fields => [ "Start", "End", "Info","Document ID", "Entity Type"])
$tchash_global_persistence = TSV.new(TCHash.get(Rbbt.tmp.test.global.persistence.find(:user), true, Persistence::TSV::StringArraySerializer), :key => "ID", :fields => [ "Start", "End", "Info","Document ID", "Entity Type"])

class Document
  define :sentences do 
    require 'rbbt/nlp/nlp'
    NLP.geniass_sentence_splitter(text)
  end

  define :tokens do
    require 'rbbt/ner/annotations/token'
    Token.tokenize(text)
  end
 
  define :long_words do
    require 'rbbt/ner/annotations/token'
    Token.tokenize(text).select{|tok| tok.length > 5}
  end

  define :short_words do
    require 'rbbt/ner/annotations/token'
    Token.tokenize(text).select{|tok| tok.length < 5}
  end
 
  define :even_words do
    require 'rbbt/ner/annotations/token'
    Token.tokenize(text).select{|tok| tok.length % 2 == 0}
  end

  define :missing do
    []
  end

  define :tokens_again do
    raise "This should be here already"
  end

  persist :sentences
  persist_in_tsv :tokens
  persist_in_tsv :long_words, $tchash_persistence, :Literal
  persist_in_global_tsv :short_words, $global_persistence
  persist_in_global_tsv :even_words, $tchash_global_persistence
  persist_in_global_tsv :missing, $tchash_global_persistence
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

    text *= 10

    TmpFile.with_file do |dir|
      FileUtils.mkdir_p dir

      doc = Document.new(dir)
      doc.text = text
      doc.sentences

      doc = Document.new(dir)
      doc.text = text

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

    text *= 10

    TmpFile.with_file do |dir|
      FileUtils.mkdir_p dir

      doc = Document.new(dir)
      doc.text = text

      sentence = doc.sentences.last
      Misc.benchmark(10) do
        doc = Document.new(dir)
        doc.text = text

        doc.load_into sentence, :tokens, :persist => true
        assert_equal 5, sentence.tokens.length
        assert_equal "another", sentence.tokens[2]
        assert_equal sentence.offset + 0, sentence.tokens[0].offset
        assert_equal sentence.offset + 5, sentence.tokens[1].offset
      end
    end
  end

  def test_annotation_persistence_in_tsv
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

      doc.load_into sentence, :tokens, :long_words

      assert_equal 5, sentence.tokens.length
      assert_equal "another", sentence.tokens[2]
      assert_equal sentence.offset + 0, sentence.tokens[0].offset

      assert_equal 2, sentence.long_words.length
      assert_equal %w(another sentence), sentence.long_words
      assert_equal sentence.offset + "This is ".length, sentence.long_words[0].offset
    end
  end

  def test_annotation_persistence_in_global
    text =<<-EOF
This is a 
sentence. This is
another sentence. 
    EOF

    TmpFile.with_file do |dir|
      FileUtils.mkdir_p dir


      doc = Document.new(dir)
      doc.text = text * 10
      doc.docid = "FOOF"
      doc.short_words
      doc.sentences

      doc = Document.new(dir)
      doc.text = text * 10
      doc.docid = "FOOF"

      sentence = doc.sentences.last

      doc.load_into sentence, :tokens, :long_words, :short_words, :even_words

      assert_equal 3, sentence.short_words.length
      assert_equal 3, sentence.even_words.length
    end
  end

  def test_dump
    text =<<-EOF
This is a 
sentence. This is
another sentence. 
    EOF

    TmpFile.with_file do |dir|
      FileUtils.mkdir_p dir

      doc = Document.new(dir)
      doc.text = text * 10
      tsv = Document.tsv(doc.sentences, ["Literal"])
   end
  end
end


