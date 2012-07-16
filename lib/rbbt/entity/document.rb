require 'rbbt/entity'
require 'rbbt/ner/segment/docid'

module Document
  extend Entity

  class << self
    attr_accessor :corpus
  end

  attr_accessor :docid

  property :docid => :single2array do |*args|
    @docid ||= if self =~ /^text:/
                 self
               else
                 ["text", Misc.digest(self.inspect)] * ":"
               end
    @docid
  end

  property :annotation_id => :single2array do |*args|
    docid(*args)
  end

  property :_get_text => :single do
    self
  end

  property :text => :array2single do |*args|
    article_text = {}
    missing = []

    if Document.corpus.nil?
      self._get_text(*args)
    else

      Document.corpus.read if Document.corpus.respond_to? :read
      self.each do |doc|

        case
        when Document.corpus.include?(doc) 
          article_text[doc] =  Document.corpus[doc] 
        when Document.corpus.include?(doc.docid(*args)) 
          article_text[doc] =  Document.corpus[doc.docid(*args)] 
        else
          missing << doc
        end

      end
      Document.corpus.close if Document.corpus.respond_to? :close

      if missing.any?
        missing.first.annotate missing
        missing_text = Misc.process_to_hash(missing){|list| list._get_text(*args)}

        Misc.lock(Document.corpus.respond_to?(:persistence_path) ? Document.corpus.persistence_path : nil) do
          Document.corpus.write if Document.corpus.respond_to? :write and not Document.corpus.write?

          missing_text.each do |doc, doc_text|
            doc = missing.first.annotate doc.dup
            Document.corpus[doc.docid(*args)] = doc_text
            article_text[doc] = doc_text
          end

          Document.corpus.close if Document.corpus.respond_to? :close
        end

      end

      article_text.values_at *self
    end
  end

end

