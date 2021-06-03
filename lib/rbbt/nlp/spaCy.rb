require 'rbbt/segment'
require 'rbbt/document'
require 'rbbt/segment/annotation'
require 'rbbt/util/python'
require 'rbbt/network/paths'

module SpaCy

  TOKEN_PROPERTIES = %w(lemma_ is_punct is_space shape_ pos_ tag_)
  CHUNK_PROPERTIES = %w(lemma_)

  def self.nlp(lang = 'en_core_web_md')
    @@nlp ||= {}
    @@nlp[lang] ||= RbbtPython.run :spacy do
      spacy.load(lang)
    end
  end

  def self.tokens(text, lang = 'en_core_web_sm')

    tokens = []

    nlp = nlp(lang)
    doc = nlp.call(text)

    doc.__len__.times do |i|
      tokens << doc.__getitem__(i)
    end

    tokens
  end

  def self.chunks(text, lang = 'en_core_web_sm')

    tokens = []
    nlp = nlp(lang)

    doc = nlp.call(text)
    chunks = doc.noun_chunks.__iter__

    RbbtPython.iterate chunks do |item|
      tokens << item
    end

    tokens
  end

  def self.segments(text, lang = 'en_core_web_sm')
    docid = text.docid if Document === text
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
    docid = text.docid if Document === text
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
      SpaCySpan.setup(chunk.text, info)
    end

    chunks
  end

  def self.dep_graph(text, reverse = false, lang = 'en_core_web_md')
    tokens = self.segments(text, lang)
    index = Segment.index(tokens)
    associations = {}
    tokens.each do |token|
      type, target_pos = token.dep.split("->")
      target_tokens = index[target_pos.to_i]
      associations[token.segid] = target_tokens
    end

    if reverse
      old = associations.dup
      old.each do |s,ts|
        ts.each do |t|
          associations[t] ||= []
          associations[t] += [s] unless associations[t].include?(s)
        end
      end
    end

    associations
  end

  def self.chunk_dep_graph(text, reverse = false, lang = 'en_core_web_md')
    associations = dep_graph(text, false, lang)

    chunks = self.chunk_segments(text, lang)
    tokens = self.segments(text, lang)
    index = Segment.index(tokens + chunks)

    chunks.each do |chunk|
      target_token_ids = chunk.dep.split(";").collect do|dep|
        type, target_pos = dep.split("->")
        index[target_pos.to_i]
      end.flatten

      target_tokens = target_token_ids.collect do |target_token_id|
        range = Range.new(*target_token_id.split(":").last.split("..").map(&:to_i))
        range.collect do |pos|
          index[pos]
        end.uniq
      end.flatten
      associations[chunk.segid] = target_tokens
    end

    if reverse
      old = associations.dup
      old.each do |s,ts|
        ts.each do |t|
          associations[t] ||= []
          associations[t] += [s] unless associations[t].include?(s)
        end
      end
    end

    associations
  end

  def self.paths(text, source, target, reverse = true, lang = 'en_core_web_md')
    graph = SpaCy.chunk_dep_graph(text, reverse, lang)

    chunk_index = Segment.index(SpaCy.chunk_segments(text, lang))

    source_id = chunk_index[source.offset].first || source.segid
    target_id = chunk_index[target.offset].first || target.segid

    path = Paths.dijkstra(graph, source_id, [target_id])

    return nil if path.nil?

    path.reverse
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

module SpaCySpan
  extend Entity
  include SegmentAnnotation

  self.annotation *SpaCy::CHUNK_PROPERTIES
  self.annotation :dep
end

