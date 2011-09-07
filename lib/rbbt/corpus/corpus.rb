require 'rbbt/corpus/document'
require 'rbbt/corpus/document_repo'

class Corpus
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
    end

 end

  def persistence_for(docid)
    File.join(persistence_dir, docid)
  end

  def document(namespace, id, type, hash)
    docid = [namespace, id, type, hash] * ":"
    Document.new(persistence_for(docid), docid, @document_repo[docid], @global_annotations)
  end

  def docid(docid)
    Document.new(persistence_for(docid), docid, @document_repo[docid], @global_annotations)
  end

  def add_document(text, namespace, id, type = nil)
    hash = Digest::MD5.hexdigest(text)
    @document_repo.add(text, namespace, id, type, hash)
  end

  def find(namespace=nil, id = nil, type = nil, hash = nil)
    @document_repo.find(namespace, id, type, hash).collect{|docid|
      Document.new(persistence_for(docid), docid, @document_repo[docid], @global_annotations)
    }
  end

  def find_docid(docid)
    @document_repo.find_docid(docid).collect{|docid|
      Document.new(persistence_for(docid), docid, @document_repo[docid], @global_annotations)
    }
  end

  def exists?(namespace=nil, id = nil, type = nil, hash = nil)
    find(namespace, id, type, hash).any?
  end
end
