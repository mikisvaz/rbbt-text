require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/corpus/document'
require 'test/unit'

class Document
  define :sentences do 
    require 'rbbt/nlp/nlp'
    NLP.geniass_sentence_splitter(text)
  end

  define :tokens do
    require 'rbbt/ner/segment/token'
    Token.tokenize(text)
  end
 
  define :long_words do
    require 'rbbt/ner/segment/token'
    Token.tokenize(text).select{|tok| tok.length > 5}
  end

  define :short_words do
    require 'rbbt/ner/segment/token'
    Token.tokenize(text).select{|tok| tok.length < 5}
  end
 
  define :even_words do
    require 'rbbt/ner/segment/token'
    Token.tokenize(text).select{|tok| tok.length % 2 == 0}
  end

  define :missing do
    []
  end

  define :tokens_again do
    raise "This should be here already"
  end
end

class TestDocument < Test::Unit::TestCase

  def setup
    global_fields = ["Start", "End", "JSON", "Document ID", "Entity Type"]
    $persistence = TSV.setup({})
    $tchash_persistence = Persist.open_tokyocabinet(Rbbt.tmp.test.document.persistence.find(:user), true, :tsv)
    $global_persistence = TSV.setup({}, :key => "ID", :fields => global_fields)
    $tchash_global_persistence = TSV.setup(Persist.open_tokyocabinet(Rbbt.tmp.test.global.persistence.find(:user), true, :list), :key => "ID", :fields => global_fields + ["Document ID", "Entity Type"])
    $tchash_global_persistence.read
    $tchash_global_persistence.write

    Document.class_eval do

      persist :sentences
      persist_in_tsv :tokens, :literal
      persist_in_tsv :long_words, $tchash_persistence, :literal
      persist_in_global_tsv :short_words, $global_persistence
      persist_in_global_tsv :even_words, $tchash_global_persistence
      persist_in_global_tsv :missing, $tchash_global_persistence
    end
  end

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
      Misc.benchmark(1) do
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
      doc = Document.new(dir)
      doc.text = text * 10
      doc.sentences
      assert_equal sentence, doc.sentences.last

      sentence = doc.sentences.last
      doc.load_into sentence, :tokens, :long_words

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


      global_persistence = TSV.setup({}, :fields => %w(Start End annotation_types JSON) + ["Document ID", "Entity Type"])
      doc = Document.new(dir, nil, nil, global_persistence)
      doc.text = text * 10
      doc.docid = "TEST"

      doc.sentences

      doc = Document.new(dir)
      doc.text = text * 10
      doc.docid = "TEST"

      sentence = doc.sentences.last

      doc.load_into sentence, :tokens, :long_words, :short_words, :even_words

      assert_equal 3, sentence.short_words.length
      assert_equal 3, sentence.even_words.length
    end
  end
end


