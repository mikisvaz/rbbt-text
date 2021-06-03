require File.join(File.expand_path(File.dirname(__FILE__)), '', 'test_helper.rb')
require 'rbbt/nlp/spaCy'
require 'rbbt/document/corpus'

class TestSpaCy < Test::Unit::TestCase
  def test_tokens
    text = "I tell a story"

    tokens = SpaCy.tokens(text)

    assert_equal 4, tokens.length
    assert_equal "tell", tokens[1].to_s
  end

  def test_chunks
    text = "Miguel Vazquez tell a good story"

    tokens = SpaCy.chunks(text)

    assert_equal 2, tokens.length
    assert_equal "Miguel Vazquez", tokens[0].to_s
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

  def test_chunk_segments
    text = "I tell a story. It's a very good story."

    corpus = Document::Corpus.setup({})

    Document.setup(text, "TEST", "test_doc1", "simple_sentence")

    corpus.add_document text
    text.corpus = corpus

    segments = SpaCy.chunk_segments(text)

    segments.each do |segment|
      assert_equal segment, segment.segid.tap{|e| e.corpus = corpus}.segment
    end
  end

  def test_dep_graph
    text = "Meanwhile, TF antisense treatment activated the human ASBT promoter 5-fold and not only abrogated interleukin-1beta-mediated repression but led to a paradoxical increase in TG promoter activity"
    graph = SpaCy.dep_graph(text, true)

    tokens = SpaCy.segments(text)
    index = Segment.index tokens
    tf_s = tokens.select{|t| t == "TF" }.first
    tg_s = tokens.select{|t| t == "TG" }.first

    require 'rbbt/network/paths'

    path = Paths.dijkstra(graph, tf_s.segid, [tg_s.segid])
    path_tokens = path.collect do |segid|
      range = Range.new(*segid.split(":").last.split("..").map(&:to_i))
      text[range]
    end

    assert path_tokens.include? 'increase'

  end

  def test_chunk_dep_graph
    text = "Meanwhile, TF antisense treatment activated the human ASBT promoter 5-fold and not only abrogated interleukin-1beta-mediated repression but led to a paradoxical increase in TG promoter activity"
    graph = SpaCy.chunk_dep_graph(text, true)

    tokens = SpaCy.chunk_segments(text)
    index = Segment.index tokens
    tf_s = tokens.select{|t| t.include? "TF" }.first
    tg_s = tokens.select{|t| t.include? "TG" }.first


    require 'rbbt/network/paths'

    path = Paths.dijkstra(graph, tf_s.segid, [tg_s.segid])
    path_tokens = path.collect do |segid|
      range = Range.new(*segid.split(":").last.split("..").map(&:to_i))
      text[range]
    end

    assert path_tokens.include? 'increase'
  end

  def test_paths
    text = "Meanwhile, TF antisense treatment activated the human ASBT promoter 5-fold and not only abrogated interleukin-1beta-mediated repression but led to a paradoxical increase in TG promoter activity"
    path = SpaCy.paths(text, Segment.setup("TF", :offset => text.index("TF")), Segment.setup("TG",:offset =>  text.index("TG")))


    path_tokens = path.collect do |segid|
      range = Range.new(*segid.split(":").last.split("..").map(&:to_i))
      text[range]
    end

    ppp text
    iii path_tokens

    assert path_tokens.include? 'increase'
  end

  def test_paths2
    text = "Deletion and domain swap experiments identified small, discreet positive and negative elements in A-Myb and TF that were required for the regulation of specific genes, such as DHRS2, TG, and mim-1"
    path = SpaCy.paths(text, Segment.setup("TF", :offset => text.index("TF")), Segment.setup("TG",:offset =>  text.index("TG")))


    path_tokens = path.collect do |segid|
      range = Range.new(*segid.split(":").last.split("..").map(&:to_i))
      text[range]
    end
    
    iii path_tokens


    assert path_tokens.include? 'regulation'
  end

  def test_paths3
    text = "Therefore, we speculate that PEA3 factors may contribute to the up-regulation of COX-2 expression resulting from both APC mutation and Wnt1 expression"
    path = SpaCy.paths(text, *Segment.align(text,["PEA3", "Wnt1"]))

    path_tokens = path.collect do |segid|
      range = Range.new(*segid.split(":").last.split("..").map(&:to_i))
      text[range]
    end

  end
end

