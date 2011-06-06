require 'rbbt/util/tsv'
require 'rbbt/ner/annotations'
require 'json'
class AnnotationRepo < TSV
  attr_accessor :docid_index, :type_index
  def initialize(path_to_db)
    if File.exists? path_to_db
      super TCHash.get(path_to_db, false, TCHash::StringArraySerializer)
    else
      super TCHash.get(path_to_db, true, TCHash::StringArraySerializer)
      self.data.write
      self.fields    = ["Document ID", "Type", "Start", "End", "Info"]
      self.key_field = "Annotation"
      self.data.read
    end
    @docid_index = {}
    @type_index = {}
  end

  def docid_index(docid)
    return @docid_index[docid] if @docid_index.include? docid
    updated = @docid_index.keys

    through{|id, values|
      annot_docid = values.first
      next if updated.include? docid
      @docid_index[annot_docid] ||= [] 
      @docid_index[annot_docid] << id
    }

    @docid_index[docid] || []
  end

  def type_index(type)
    return @type_index[type] if @type_index.include? type
    updated = @type_index.keys

    through{|id, values|
      annot_type = values[1]
      next if updated.include? type
      @type_index[annot_type] ||= [] 
      @type_index[annot_type] << id
    }

    @type_index[type] || []
  end

  def clean_index(docid, type)
    @docid_index.delete docid
    @type_index.delete type
  end

  def add_annotations(docid, type)
    read
    annotations = self.values_at(*(docid_index(docid) & type_index(type)))

    if annotations.empty?
      annotations = yield 
      annotations = [Segment.annotate("NO-ANNOTATIONS-FOUND", nil, docid)] if annotations.empty?
      begin
        @annotation_index.delete docid if not @annotation_index.nil? and @annotation_index.include? docid
        write
        clean_index(docid, type)
        annotations.each do |annotation|
          annotation.docid = docid
          self[annotation.id] = [docid, type, annotation.offset, annotation.end, annotation.info.to_json]
        end
      ensure
        read
      end
    else
    end

    annotations.reject{|annotation| annotation == "NO-ANNOTATIONS-FOUND"}
  end

  def merge(tsv)
    write
    tsv.each do |code, values|
      self[code] = values
    end
    read
  end

  def annotation_index(docid = :all)
    @annotation_index ||= {}
    return @annotation_index[docid] if @annotation_index.include? docid

    value_size = self.keys.collect{|k| k.length}.max

    annotation_index = @annotation_index[docid] ||= FixWidthTable.new(:memory, value_size, true)
    data = self.collect{|key,annotation| 
      next if docid != :all and annotation[0] != docid 
      next if annotation[2].nil? or (String === annotation[2] and annotation[2].empty?)
      [key, annotation.values_at(2, 3).collect{|v| v.to_i}]
    }.compact
    annotation_index.add_range data
    annotation_index
  end

  def annotations_at(docid, pos, type = nil)
    annotations = annotation_index(docid)[pos].collect{|id| self[id]}
    annotations = annotations.select{|annotation| annotation[1] == type} if type
    annotations
  end
end
