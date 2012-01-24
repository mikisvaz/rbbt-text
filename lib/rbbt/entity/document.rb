require 'rbbt/entity'

module Document
  extend Entity

  class << self
    attr_accessor :corpus
  end

  property :text => :array2single do
    article_text = {}
    missing = []

    self.each do |doc|
      Document.corpus.read if Document.corpus.respond_to? :read
      if Document.corpus.include?(doc) 
        article_text[doc] =  Document.corpus[doc] 
      else
        missing << doc
      end
    end

    if missing.any?
      missing.first.annotate missing
      missing_text = Misc.process_to_hash(missing){|list| list._get_text}

      Misc.lock Document.corpus.persistence_path do
        Document.corpus.write if Document.corpus.respond_to? :write
        missing_text.each do |doc, text|
          article_text[doc] = text
          Document.corpus[doc] = text
        end
        Document.corpus.read if Document.corpus.respond_to? :read
      end
    end

    article_text.values_at *self
  end

end
