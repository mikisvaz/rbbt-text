require File.join(File.expand_path(File.dirname(__FILE__)), '', 'test_helper.rb')
require 'rbbt/nlp/spaCy'
require 'rbbt/document/corpus'

class TestSpaCy < Test::Unit::TestCase
  def _test_tokens
    text = "I tell a story"

    tokens = SpaCy.tokens(text)

    assert_equal 4, tokens.length
    assert_equal "tell", tokens[1].to_s
  end

  def test_segments
    text = "I tell a story. It's a very good story."

    corpus = Document::Corpus.setup({})

    Document.setup(text, "TEST", "test_doc1", "simple_sentence")

    corpus.add_document text
    text.corpus = corpus

    segments = SpaCy.segments(text)

    segments.each do |segment|
      assert_equal segment, segment.segid.tap{|e| e.corpus = corpus}.segment
    end
  end
end

