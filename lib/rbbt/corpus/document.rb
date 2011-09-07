require 'rbbt/ner/segment'
require 'rbbt/ner/segment/segmented'
require 'rbbt/tsv'
require 'rbbt/resource/path'
require 'rbbt/persist/tsv'
require 'rbbt/util/misc'
require 'json'

class Document

  attr_accessor :text, :docid, :namespace, :id, :type, :hash, :segments, :segment_indeces, :persist_dir, :global_persistence
  def initialize(persist_dir = nil, docid = nil, text = nil, global_persistence = nil)
    @segments = {}
    @segment_indeces = {}

    if not persist_dir.nil?
      @persist_dir = persist_dir
      @persist_dir = Path.setup(@persist_dir) if not Path == @persist_dir
    end

    @global_persistence = global_persistence

    if not docid.nil?
      @docid = docid 
      update_docid
    end
    @text = text unless text.nil?
  end

  def update_docid
    @namespace, @id, @type, @hash = docid.split(":", -1)
  end

  def docid=(docid)
    @docid = docid 
    update_docid
  end

  #{{{ PERSISTENCE

  TSV_REPOS = {}
  FIELDS_FOR_ENTITY_PERSISTENCE = {}
  def self.persist(entity, fields = nil)

    if not fields.nil?
      fields = [fields] if not Array === fields
      fields = fields.collect{|f| f.to_s}
      FIELDS_FOR_ENTITY_PERSISTENCE[entity.to_s] = fields
    end

    self.class_eval <<-EOC
      def load_with_persistence_#{entity}(raw = false)
        fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]

        tsv_file = File.join(@persist_dir.find, "#{ entity }")

        return nil if raw == :check and File.exists? tsv_file

        annotations = Persist.persist("Entity[#{ entity }]", :tsv, :file => tsv_file) do 
          segments = produce_#{entity}
          tsv = Segment.tsv(segments, fields)
        end

        return annotations if raw

        annotations.unnamed = true
        annotations.collect{|id, annotation| 
          Segment.load_tsv_values(text, annotation, annotations.fields)
        }
      end
          EOC
  end

  def self.persist_in_tsv(entity, tsv = nil, fields = nil)
    if not tsv.nil? and not tsv.respond_to?(:keys)
      fields = tsv
      tsv = nil
    end

    TSV_REPOS[entity.to_s] = tsv

    if not fields.nil?
      fields = [fields] if not Array === fields
      fields = fields.collect{|f| f.to_s}
      FIELDS_FOR_ENTITY_PERSISTENCE[entity.to_s] = fields unless fields.nil?
    end

    self.class_eval <<-EOC
      def load_with_persistence_#{entity}(raw = false)
        repo = TSV_REPOS["#{ entity }"]
        if repo.nil?
          raise "No persistence file or persistence dir for persist_in_tsv" if persist_dir.nil?
          repo = Persist.open_tokyocabinet(persist_dir.annotations_by_type.find, true, :marshal_tsv)
        end

        fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]
        if not repo.include? "#{ entity }"
          segments = produce_#{entity}
          repo.write
          repo["#{entity}"] = Segment.tsv(segments, fields)
          repo.read
        else
          if raw == :check
            repo.close
            return nil
          end
        end

        
        annotations = repo["#{entity}"]

        repo.close


        return annotations if raw

        annotations.unnamed = true
        annotations.collect{|id, annotation| 
          Segment.load_tsv_values(text, annotation, annotations.fields)
        }
      end
    EOC
  end
  
  def self.persist_in_global_tsv(entity, tsv = nil, fields = nil, doc_field = nil, entity_field = nil)
    doc_field ||= "Document ID" 
    entity_field ||= "Entity Type"

    TSV_REPOS[entity.to_s] = tsv

    if not fields.nil?
      fields = [fields] if not Array === fields
      fields = fields.collect{|f| f.to_s}
    else
      fields = nil
    end

    FIELDS_FOR_ENTITY_PERSISTENCE[entity.to_s] = fields 

    self.class_eval <<-EOC
      def load_with_persistence_#{entity}(raw = false)
        fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]

        data = TSV_REPOS["#{ entity }"] || @global_persistence

        data.read true

        fields = data.fields if fields.nil? and data.respond_to? :fields


        data.filter
        data.add_filter("field:#{ doc_field }", @docid)
        data.add_filter("field:#{ entity_field }", "#{ entity }")
        keys = data.keys
        data.pop_filter
        data.pop_filter

        if keys.empty?
          segments = produce_#{entity}
          segments << Segment.setup("No #{entity} found in document #{ @docid }", -1) if segments.empty?
          tsv = Segment.tsv(segments, *fields.reject{|f| ["#{doc_field}", "#{entity_field}", "Start", "End", "annotation_types"].include? f})

          tsv.add_field "#{ doc_field }" do
            @docid
          end

          tsv.add_field "#{ entity_field }" do
            "#{ entity }"
          end

          data.add_filter("field:#{ doc_field }", @docid)
          data.add_filter("field:#{ entity_field }", "#{ entity }")
          data.write true
          keys = tsv.collect do |key, value|
            data[key] = value
            key
          end
          data.pop_filter
          data.pop_filter
          data.read
        else
          if raw == :check
            data.close
            return nil
          end
        end

        return data.values if raw

        start_pos = data.identify_field "Start"
        segments = data.values_at(*keys).collect{|annotation| 
            pos = annotation[start_pos]
            Segment.load_tsv_values(text, annotation, data.fields) unless [-1, "-1", [-1], ["-1"]].include? pos
         }.compact
        data.close

        segments
      end
      EOC
  end


  def self.define(entity, &block)
    send :define_method, "produce_#{entity}", &block

    self.class_eval <<-EOC
      def load_#{entity}(raw = false)
        return if segments.include? "#{ entity }"
        if self.respond_to?("load_with_persistence_#{entity}") and not @persist_dir.nil?
          segments["#{entity}"] = load_with_persistence_#{entity}(raw)
        else
          segments["#{ entity }"] = produce_#{entity}
        end
      end

      def #{entity}(raw = false)
        begin
          entities = segments["#{ entity }"]
          if entities.nil?
            load_#{entity}(raw)
            entities = segments["#{ entity }"]
          end
        end

        entities
      end

      def #{entity}_at(pos, persist = false)
        segment_index("#{ entity }", persist ? File.join(@persist_dir, 'ranges') : nil)[pos]
      end

    EOC
  end

  def segment_index(name, persist_dir = nil)
    @segment_indeces[name] ||= Segment.index(self.send(name), persist_dir.nil? ? :memory : File.join(persist_dir, name + '.range'))
  end

  def load_into(segment, *annotations)
    options = annotations.pop if Hash === annotations.last
    options ||= {}

    if options[:persist] and not @persist_dir.nil?
      persist_dir = File.join(@persist_dir, 'ranges')
    else
      persist_dir = nil
    end

    Segmented.setup(segment, {})
    annotations.collect do |name|
      name = name.to_s
      index = segment_index(name, persist_dir)
      annotations = index[segment.range]
      segment.segments[name] = annotations
      class << segment
        self
      end.class_eval "def #{ name }; @segments['#{ name }']; end"
    end

    segment
  end
end
