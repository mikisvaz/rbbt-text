require 'rbbt/entity'
require 'rbbt/ner/segment/docid'

module Document
  extend Entity

  class << self
    attr_accessor :corpus
  end

  property :docid => :single2array do |*args|
    @docid ||= if self =~ /^text:/
                 self
               else
                 ["text", Misc.digest(self.inspect)] * ":"
               end
    @docid
  end

  property :annotation_id => :both do |*args|
    if Array === self
      Misc.hash2md5(info.merge(:self => self))
    else
      docid(*args)
    end
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

      Document.corpus.read_and_close do
        self.each do |doc|
          id = doc.docid(*args)
          case
          when Document.corpus.include?(doc) 
            article_text[doc] =  Document.corpus[doc] 
          when Document.corpus.include?(id) 
            article_text[doc] =  Document.corpus[id] 
          else
            missing << doc
          end

        end
      end

      if missing.any?
        missing.first.annotate missing
        missing_text = Misc.process_to_hash(missing){|list| list._get_text(*args)}

        Misc.lock(Document.corpus.respond_to?(:persistence_path) ? Document.corpus.persistence_path : nil) do
          Document.corpus.write_and_close do

            missing_text.each do |doc, doc_text|
              doc = self.annotate doc.dup
              Document.corpus[doc.docid(*args)] = doc_text
              article_text[doc] = doc_text
            end
          end
        end
      end

      article_text.values_at *self
    end
  end
end

