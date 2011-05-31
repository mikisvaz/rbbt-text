require 'rbbt/util/tsv'
require 'rbbt/ner/annotations'
require 'json'
class AnnotationRepo < TSV
  def initialize(path_to_db)
    if File.exists? path_to_db
      super TCHash.get(path_to_db, false)
    else
      super TCHash.get(path_to_db, true)
      self.data.write
      self.fields    = ["Document ID", "Type", "Start", "End", "Info"]
      self.key_field = "Annotation"
      self.data.read
    end
  end

  def add_annotations(docid, type)
    read
    annotations = select{|id, values|
      values["Document ID"] == docid and values["Type"] == type
    }.values

    if annotations.empty?
      annotations = yield 
      annotations = [Segment.annotate("NO-ANNOTATIONS-FOUND", nil, docid)] if annotations.empty?
      begin
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

  def annotation_index(docid = :all)
    @annotation_index ||= {}
    return @annotation_index[docid] if @annotation_index.include? docid

    value_size = self.keys.collect{|k| k.length}.max

    annotation_index = @annotation_index[docid] = FixWidthTable.new(:memory, value_size, true)
    data = self.collect{|key,annotation| 
      next if docid != :all and annotation["Document ID"] != docid 
      next if annotation["Start"].nil? or (String === annotation["Start"] and annotation["Start"].empty?)
      [key, annotation.values_at("Start", "End")]
    }.compact
    annotation_index.add_range data
    annotation_index
  end

  def annotations_at(docid, pos, type = nil)
    annotations = annotation_index(docid)[pos].collect{|id| self[id]}
    annotations = annotations.select{|annotation| annotation["Type"] == type} if type
  end
end
