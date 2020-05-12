require 'rbbt/segment'
require 'rbbt/document'
require 'rbbt/segment/annotation'
require 'rbbt/util/python'

module SpaCy

  PROPERTIES = %w(lemma_ is_punct is_space shape_ pos_ tag_)

  def self.tokens(text, lang = 'en')

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

  def self.segments(text, lang = 'en')
    docid = text.docid if Document === text 
    corpus = text.corpus if Document === text 
    tokens = self.tokens(text, lang).collect do |token|
      info = {}
      PROPERTIES.each do |p|
        info[p] = token.instance_eval(p.to_s)
      end
      info[:type] = "SpaCy"
      info[:offset] = token.idx
      info[:dep] = token.dep_ + "->" + token.head.idx.to_s
      info[:docid] = docid if docid
      info[:corpus] = corpus if corpus
      SpaCyToken.setup(token.text, info)
    end
    SpaCyToken.setup(tokens, :corpus => corpus)
  end
end

module SpaCyToken
  extend Entity
  include SegmentAnnotation

  self.annotation *SpaCy::PROPERTIES
  self.annotation :dep
end

if __FILE__ == $0
  ppp Annotated.tsv(SpaCy.segments("I tell a story"), :all)
end
