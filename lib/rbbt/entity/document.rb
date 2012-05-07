require 'rbbt/entity'

module Document
  extend Entity

  class << self
    attr_accessor :corpus
  end

  property :text => :array2single do |*args|
    article_text = {}
    missing = []

    if Document.corpus.nil?
      self._get_text(*args)
    else
      self.each do |doc|
        doc_code = args.any? ? [doc, Misc.digest(args.inspect)] * ":" : doc
        Document.corpus.read if Document.corpus.respond_to? :read

        if Document.corpus.include?(doc) 
          article_text[doc_code] =  Document.corpus[doc_code] 
        else
          missing << doc
        end
      end

      if missing.any?
        missing.first.annotate missing
        missing_text = Misc.process_to_hash(missing){|list| list._get_text(*args)}

        Misc.lock(Document.corpus.respond_to?(:persistence_path) ? Document.corpus.persistence_path : nil) do
          Document.corpus.write if Document.corpus.respond_to? :write
          missing_text.each do |doc, text|
            doc_code = args.any? ? [doc, Misc.digest(args.inspect)] * ":" : doc
            article_text[doc_code] = text
            Document.corpus[doc_code] = text
          end
          Document.corpus.read if Document.corpus.respond_to? :read
        end
      end

      article_text.values_at *self
    end
  end

end
