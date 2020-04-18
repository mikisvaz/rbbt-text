require 'rbbt-util'

module Document::Corpus

  def self.setup(corpus)
    corpus.extend Document::Corpus
  end

  def add_document(document)
    self[document.docid] = document
  end

  def [](*args)
    docid, *rest = args
    res = super(*args)
    return res if args.length > 1
    namespace, id, type  = docid.split(":")

    if res.nil?
      if Document::Corpus.claims.include?(namespace.to_s)
        res = self.instance_exec(id, type, &Document::Corpus.claims[namespace.to_s])
      end
    end

    Document.setup(res, namespace, id, type, self) unless res.nil?
    
    res
  end

  class << self
    attr_accessor :claims
    def claim(namespace, &block)
      @claims = {}
      @claims[namespace.to_s] = block
    end
  end

end
