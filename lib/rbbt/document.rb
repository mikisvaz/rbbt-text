require 'rbbt-util'
require 'rbbt/entity'

module DocID
  extend Entity
  self.annotation :corpus

  class << self
    attr_accessor :default_corpus
  end

  def corpus
    annotation_values[:corpus] || DocID.default_corpus
  end

  property :to do |type|
    namespace, code = self.split(":")
    DocID.setup([namespace, code, "title"] * ":", :corpus => corpus)
  end

  property :document => :both do
    if Array === self
      namespace, id, type = nil, nil, nil
      docs = self.collect do |docid|
        text = self.corpus[docid]
        namespace, id, type = docid.split(":")
        text
      end
      Document.setup(docs, :corpus => corpus)
    else
      text = self.corpus[self]
      namespace, id, type = self.split(":")
      Document.setup(text, :namespace => namespace, :code => id, :type => type, :corpus => corpus)
    end
  end
end

module Document
  extend Entity
  self.annotation :namespace, :code, :type, :corpus

  property :docid do |corpus=nil|
    digest = Misc.digest(self)
    corpus = self.corpus if corpus.nil?

    DocID.setup([namespace, code, type, digest] * ":", :corpus => corpus)
  end

  property :to do |type|
    docid.to(type).document
  end

  alias id docid
end

