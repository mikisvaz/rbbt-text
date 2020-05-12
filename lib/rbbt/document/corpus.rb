require 'rbbt-util'

module Document::Corpus

  def self.setup(corpus)
    corpus.extend Document::Corpus unless Document::Corpus === corpus
    corpus.extend Persist::TSVAdapter unless Persist::TSVAdapter === corpus
    corpus
  end

  def add_document(document)
    docid = document.docid
    return document if self.include?(docid)
    self.write_and_close do
      self[docid] = document
    end
  end
  
  def docids(prefix)
    prefix += ":" unless prefix[-1] == ":"
    docids = self.read_and_close do
      self.prefix(prefix)
    end
    DocID.setup(docids, :corpus => self)
  end

  def documents(prefix)
    self.docids(prefix).document
  end

  def [](*args)
    docid, *rest = args

    res = self.read_and_close do
      super(*args)
    end
    
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
