require 'rbbt/util/tsv'
require 'rbbt/ner/annotations'
require 'rbbt/util/tsv/filters'
require 'json'
require 'set'

class AnnotationRepo < TSV
  attr_accessor :filter_dir
  def initialize(path_to_db, filter_dir = nil)
    if File.exists? path_to_db
      super TCHash.get(path_to_db, false, TCHash::StringArraySerializer)
    else
      super TCHash.get(path_to_db, true, TCHash::StringArraySerializer)
      self.data.write
      self.fields    = ["Document ID", "Type", "Start", "End", "Info"]
      self.key_field = "Annotation"
      self.data.read
      self.filename = path_to_db
      self.data.filename = path_to_db
    end
    filter
    @filter_dir = filter_dir || path_to_db + ".filters"
  end

  def with_filter(docid = nil, type = nil)
    filters.clear
    add_filter("field:Document ID", docid) unless docid.nil?
    add_filter("field:Type", type) unless type.nil?
    res = yield
    pop_filter unless type.nil?
    pop_filter unless docid.nil?
    res
  end

  def filtered_ids(docid = nil, type = nil)
    with_filter(docid, type) do keys end
  end

  def reset_filters
    filters.each do |filter| filter.reset end
  end

  def clear_filters
    Dir.glob(File.join(filter_dir, "*")).each do |file| TCHash.get(file).close; FileUtils.rm file end if filter_dir
  end

  def add_comment(docid, type, comment)
    self[comment.id] = [docid, type, nil, nil, comment]
  end

  def add_segment(docid, type, segment)
    self[segment.id] = [docid, type, segment.offset, segment.end, segment.info.to_json]
  end
  
  def add_segments(docid, type, segments)
    segments.each do |segment| self[segment.id] = [docid, type, segment.offset, segment.end, segment.info.to_json] end
  end

  def update_filters
    filters.each do |filter| filter.add_unsaved end
    FileUtils.rm Dir.glob(filename + '*Index*')
  end

  def produce_segments(docid, type, &block)
    segments = block.call 
    segments = [Segment.annotate("NO-ANNOTATIONS-FOUND", nil, docid)] if segments.empty?

    begin
      write
      with_filter(docid, type) do
        segments.each do |segment|
          segment.docid = docid
          add_segment(docid, type, segment)
        end
        update_filters 
      end
    ensure
      read
    end
  end

  def updated_segments(docid, type, &block)
    read
    annotation_ids = filtered_ids(docid, type)

    return annotation_ids if annotation_ids.any?

    segments = if annotation_ids.empty?
                 produce_segments(docid, type, &block)
               else
                 self.values_at(*annotation_ids)
               end 

    segments.reject{|segment| segment == "NO-ANNOTATIONS-FOUND"}
  end

  def clear_annotations(docid = nil, type = nil)
    restore = ! self.write?
    write unless self.write?

    ids = with_filter(docid, type) do
      filters.each do |filter| filter.reset end
    end

    read if restore

    ids.each do |id| self.delete id end
  end

  def merge(tsv)
    write
    tsv.each do |code, values|
      self[code] = values
    end
    read
  end

  def load_segment(text, annotation)
    docid, type, start, eend, info = annotation.values_at(0, 1, 2, 3, 4)
    Segment.load(text, start, eend, JSON.parse(info), docid)
  end

  def segments(text)
    values.collect{|annotation| load_segment(text, annotation)}
  end

  def filtered_annotations(docid = nil, type = nil)
    with_filter(docid, type) do
      values
    end
  end

  def filtered_segments(text, docid = nil, type = nil)
    with_filter(docid, type) do
      segments(text)
    end
  end

  def annotations_at(pos, docid = nil, type = nil)
    with_filter(docid, type) do
      if keys.any?
        range_index("Start", "End")[pos] 
      else
        []
      end
    end
  end

  def segments_at(text, pos, docid = nil, type = nil)
    with_filter(docid, type) do
      range_index("Start", "End")[pos].collect{|annotation| load_segment(text, self[annotation])}
    end
  end

  def dump(docid = nil, type = nil)
    with_filter(docid, type) do
      to_s
    end
  end
end
