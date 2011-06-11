require 'rbbt/util/resource'
require 'rbbt/sources/pubmed'
require 'digest/md5'
require 'rbbt/annotations/corpus/document_repo'
require 'rbbt/annotations/corpus/annotation_repo'
require 'rbbt/annotations/document'
require 'rbbt/annotations/entities'
require 'rbbt/annotations/sentence'
require 'json'

class Corpus
  NAMESPACES = {} unless defined? NAMESPACES

  attr_accessor :corpora_path, :document_repo, :annotation_repo
  def initialize(corpora_path = nil)
    @corpora_path = case
                   when corpora_path.nil?
                     Rbbt.corpora
                   when (not Resource::Path === corpora_path)
                     Path.path(corpora_path)
                   else
                     corpora_path
                   end

    @document_repo   = DocumentRepo.get @corpora_path.document_repo, false
    @annotation_repo = AnnotationRepo.new @corpora_path.annotation_repo
    @annotation_repo.unnamed = true
  end

  #{{{ Documents
 
  def document(namespace, id, type, hash)
    Document.new(self,namespace, id, type, hash)
  end

  def docid(docid)
    Document.new(self, *docid.split(":", -1))
  end

  def text(docid)
    @document_repo.docid(docid)
  end

  def add_document(text, namespace, id, type = nil)
    hash = Digest::MD5.hexdigest(text)
    @document_repo.add(text, namespace, id, type, hash)
  end

  def find(namespace=nil, id = nil, type = nil, hash = nil)
    @document_repo.find(namespace, id, type, hash).collect{|key|
      Document.new(self, *key.split(":", -1).values_at(0,1,2,3))
    }
  end

  def find_docid(docid)
    @document_repo.find_docid(docid).collect{|key|
      Document.new(self, *DocumentRepo.docid2fields(key))
    }
  end


  def exists?(namespace=nil, id = nil, type = nil, hash = nil)
    find(namespace, id, type, hash).any?
  end

  #{{{ Annotations
  
  def load(tsv)
    @annotation_repo.merge(tsv)
    tsv.through :key, "Document ID" do |id, values|
      docid = values.first
      if not @document_repo.include?(docid)
        namespace, id, type = docid.split(":", -1)
        self.send(NAMESPACES[namespace.to_sym], id, type)
      end
    end
  end

  def load_segment(annotation)
    return annotation if Segment === annotation
    docid, type, start, eend, info = annotation.values_at(0, 1, 2, 3, 4)
    document = self.docid(docid)
    annotation = Segment.load(document.text, start, eend, JSON.parse(info))
    annotation
  end

  def add_annotations(docid, type, noload = false, &block)
    @annotation_repo.add_annotations(docid, type, noload, &block).collect{|annotation| load_segment(annotation) unless noload}
  end

  def annotations_at(docid, pos, type = nil)
    @annotation_repo.annotations_at(docid, pos, type).collect{|annotation| load_segment(annotation)}
  end

  def annotations
    @annotation_repo.to_s
  end

  def clear_annotations(*args)
    annotation_repo.clear_annotations(*args)
  end
end

Corpus.define_entity_ner("Sentences", false) do |doc| NLP.geniass_sentence_splitter(doc.text) end
