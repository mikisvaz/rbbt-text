require 'rbbt/segment'
require 'rbbt/document'
require 'rbbt/segment/annotation'
require 'rbbt/util/python'

module SpaCy

  TOKEN_PROPERTIES = %w(lemma_ is_punct is_space shape_ pos_ tag_)
  CHUNK_PROPERTIES = %w(lemma_)

  def self.tokens(text, lang = 'en_core_web_sm')

    tokens = []
    RbbtPython.run 'spacy' do
      nlp = spacy.load(lang)
      doc = nlp.call(text)
      doc.__len__.times do |i|
        tokens << doc.__getitem__(i)
      end
    end
    tokens
  end

  def self.chunks(text, lang = 'en_core_web_sm')

    tokens = []
    RbbtPython.run 'spacy' do
      nlp = spacy.load(lang)
      doc = nlp.call(text)
      chunks = doc.noun_chunks.__iter__

      RbbtPython.iterate chunks do |item|
        tokens << item
      end
    end
    tokens
  end

  def self.segments(text, lang = 'en_core_web_sm')
    docid = text.docid 
    corpus = text.corpus if Document === text 
    tokens = self.tokens(text, lang).collect do |token|
      info = {}
      TOKEN_PROPERTIES.each do |p|
        info[p] = token.instance_eval(p.to_s)
      end
      info[:type] = "SpaCy"
      info[:offset] = token.idx
      info[:dep] = token.dep_ + "->" + token.head.idx.to_s
      info[:docid] = docid if docid
      info[:corpus] = corpus if corpus
      SpaCyToken.setup(token.text, info)
    end

    tokens
  end

  def self.chunk_segments(text, lang = 'en_core_web_sm')
    docid = text.docid 
    corpus = text.corpus if Document === text 
    chunks = self.chunks(text, lang).collect do |chunk|
      info = {}
      CHUNK_PROPERTIES.each do |p|
        info[p] = chunk.instance_eval(p.to_s)
      end
      start = eend =  nil
      deps = []
      RbbtPython.iterate chunk.__iter__ do |token|
        start = token.idx if start.nil?
        eend = start + chunk.text.length if eend.nil?
        deps << token.idx.to_s + ":" + token.dep_ + "->" + token.head.idx.to_s if token.head.idx < start || token.head.idx > eend
      end
      info[:type] = "SpaCy"
      info[:offset] = chunk.__iter__.__next__.idx
      info[:dep] = deps * ";"
      info[:docid] = docid if docid
      info[:corpus] = corpus if corpus
      SpaCyToken.setup(chunk.text, info)
    end

    chunks
  end

  def self.config(base, target = nil)
    TmpFile.with_file(base) do |baseconfig|
      if target
        CMD.cmd(:spacy, "init fill-config #{baseconfig} #{target}")
      else
        TmpFile.with_file do |tmptarget|
          CMD.cmd(:spacy, "init fill-config #{baseconfig} #{tmptarget}")
          Open.read(targetconfig)
        end
      end
    end
  end
end

module SpaCyToken
  extend Entity
  include SegmentAnnotation

  self.annotation *SpaCy::TOKEN_PROPERTIES
  self.annotation :dep
end

module SpaCyChunk
  extend Entity
  include SegmentAnnotation

  self.annotation *SpaCy::CHUNK_PROPERTIES
  self.annotation :dep
end

if __FILE__ == $0
  document = Document.setup("I tell a story")
  segments = SpaCy.segments(document)
  ppp Annotated.tsv(segments, :all)
  segments = SpaCy.chunk_segments(document)
  ppp Annotated.tsv(segments, :all)
end
