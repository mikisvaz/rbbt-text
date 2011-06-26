require 'rbbt/corpus/document'
require 'rbbt/corpus/document_repo'

class Corpus
  attr_accessor :corpora_path, :document_repo, :persistence_dir, :global_annotations
  def initialize(corpora_path = nil)
    @corpora_path = case
                   when corpora_path.nil?
                     Rbbt.corpora
                   when (not Resource::Path === corpora_path)
                     Resource::Path.path(corpora_path)
                   else
                     corpora_path
                   end

    @document_repo   = DocumentRepo.get @corpora_path.document_repo, false
    @persistence_dir = File.join(@corpora_path, "annotations")
    @global_annotations = TSV.new(TCHash.get(File.join(@persistence_dir, "global_annotations"), :list), :list, :key => "ID", :fields => [ "Start", "End", "Info","Document ID", "Entity Type"])
    @global_annotations.unnamed = true
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
