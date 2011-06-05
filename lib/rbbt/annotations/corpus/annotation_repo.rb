require 'rbbt/util/tsv'
require 'rbbt/ner/annotations'
require 'json'
class AnnotationRepo < TSV
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
  end

  def add_annotations(docid, type)
    read
    annotations = select{|id, values|
      [docid, type] == values.values_at(0, 1)
    }.values

    if annotations.empty?
      annotations = yield 
      annotations = [Segment.annotate("NO-ANNOTATIONS-FOUND", nil, docid)] if annotations.empty?
      begin
        @annotation_index.delete docid if not @annotation_index.nil? and @annotation_index.include? docid
        write
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
