require 'rbbt/util/resource'
require 'rbbt/sources/pubmed'
require 'digest/md5'
require 'rbbt/annotations/corpus/document_repo'
require 'rbbt/annotations/corpus/annotation_repo'
require 'rbbt/annotations/document'
require 'rbbt/annotations/entities'
require 'rbbt/annotations/sentence'

class Corpus
  NAMESPACES = {} unless defined? NAMESPACES

  attr_accessor :corpora_path, :document_repo, :annotation_repo
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
    @annotation_repo.clear_filters
    tsv.through :key, "Document ID" do |id, values|
      docid = values.first
      if not @document_repo.include?(docid)
        namespace, id, type = docid.split(":", -1)
        self.send(NAMESPACES[namespace.to_sym], id, type)
      end
    end
  end

  def update_segments(docid, type, &block)
    @annotation_repo.updated_segments(docid, type, &block)
  end

  def load_segment(text, annotation)
    @annotation_repo.load_segment(text, annotation)
  end

  def segment_for(text, annotation_id)
    @annotation_repo.segment_for(text, annotation_id)
  end

  def segments(docid, type, &block)
    @annotation_repo.updated_segments(docid, type, &block)
    text = docid(docid).text
    @annotation_repo.filtered_segments(text, docid, type)
  end

  def annotation_index(docid, type = nil)
    @annotation_repo.annotation_index(docid, type)
  end

  def annotations_at(pos, docid, type = nil)
    annotation_index(pos, docid, type)
  end

  def segments_at(pos, docid, type = nil)
    text = docid(docid).text
    @annotation_repo.segments_at(text, pos, docid, type)
  end

  def annotations_for(docid, type)
    annotation_repo.filtered_annotations(docid, type)
  end

  def segments_for(docid, type)
    annotation_repo.filtered_annotations(docid, type)
  end

  def clear_annotations(*args)
    annotation_repo.clear_annotations(*args)
  end

  def dump_annotations(docid = nil, type = nil, text = false)
    return annotation_repo.dump(docid, type) unless text
    annotation_repo.filtered_annotations(docid, type).collect do |annotation|
      docid = annotation.first
      text = docid(docid).text
      segment = load_segment(text, annotation)
      puts (annotation.dup.unshift segment) * "\t"
    end * "\n"
  end

  def clean(docid = nil, type = nil)
    restore = ! annotation_repo.write?
    annotation_repo.write
    annotation_repo.clean(docid, type)
    annotation_repo.clear_filters
    annotation_repo.read if restore
  end

end

Corpus.define_entity_ner("Sentences", false) do |doc| NLP.geniass_sentence_splitter(doc.text) end
