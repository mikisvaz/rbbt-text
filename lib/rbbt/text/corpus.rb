require 'rbbt/text/corpus/document'
require 'rbbt/text/corpus/document_repo'

class Corpus
  class << self
    attr_accessor :claims
    def claim(namespace, &block)
      @@claims = {}
      @@claims[namespace] = block
    end

  end
  attr_accessor :corpora_path, :document_repo, :persistence_dir, :global_annotations

  def initialize(corpora_path = nil)
    @corpora_path = case
                   when corpora_path.nil?
                     Rbbt.corpora
                   when (not Path === corpora_path)
                     Path.setup(corpora_path)
                   else
                     corpora_path
                   end

    @corpora_path = @corpora_path.find
    @persistence_dir = File.join(@corpora_path, "annotations")

    Misc.lock(@persistence_dir) do
      @global_annotations = TSV.setup(Persist.open_tokyocabinet(File.join(@persistence_dir, "global_annotations"), false, :list), :key => "ID", :fields => ["Start", "End", "JSON", "Document ID", "Entity Type"])
      @global_annotations.unnamed = true
      @global_annotations.close
    end
 
    Misc.lock(@corpora_path.document_repo) do
      @document_repo   = DocumentRepo.open_tokyocabinet @corpora_path.document_repo, false
      @document_repo.close
    end

 end

  def persistence_for(docid)
    File.join(persistence_dir, docid)
  end


  def docid(docid)
    begin
      if @document_repo.include?(docid)
        Document.new(persistence_for(docid), docid, @document_repo[docid], @global_annotations, self)
      else
        namespace, id, type = docid.split(":")
        if @@claims.include?(namespace)

          docid = self.instance_exec id, type, &(@@claims[namespace])
          docid = docid.first if Array === docid
          self.docid(docid)
        else
          raise "Document '#{ docid }' was not found." unless @document_repo.include? docid
        end
      end
    ensure
      @document_repo.close
    end
  end

  def document(namespace, id, type, hash)
    docid = [namespace, id, type, hash] * ":"
    self.docid(docid)
  end

  def add_document(text, namespace = nil, id = nil, type = nil)
    text = Misc.fixutf8(text)
    hash = Digest::MD5.hexdigest(text)
    @document_repo.add(text, namespace, id, type, hash)
  end

  def add_docid(text, docid)
    namespace, id, type, hash = docid.split(":")
    @document_repo.add(text, namespace, id, type, hash)
  end


  def find(namespace=nil, id = nil, type = nil, hash = nil)
    @document_repo.find(namespace, id, type, hash).collect{|docid|
      self.docid(docid)
    }
  end

  def find_docid(docid)
    @document_repo.find_docid(docid).collect{|docid|
      self.docid(docid)
    }
  end

  def exists?(namespace=nil, id = nil, type = nil, hash = nil)
    find(namespace, id, type, hash).any?
  end

  def [](docid)
    self.docid(docid)
  end
  
  def include?(id)
    @document_repo.include? id
  end
end
