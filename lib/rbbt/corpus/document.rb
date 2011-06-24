require 'rbbt/util/tsv'
require 'rbbt/util/misc'
require 'json'

class Document

  attr_accessor :text, :docid, :namespace, :id, :type, :hash, :annotations, :segment_indeces, :persistence_dir
  def initialize(persistence_dir = nil, docid = nil, text = nil)
    @annotations = {}
    @segment_indeces = {}
    @persistence_dir = persistence_dir unless persistence_dir.nil?
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

  def self.save_segment(segment, fields = nil)
    if fields.nil?
      [segment.offset, segment.end, segment.info.to_json]
    else
      info = segment.info
      info["literal"] = segment.to_s.gsub(/\s/,' ')
      info.extend IndiferentHash
      [segment.offset, segment.end].concat info.values_at(*fields.collect{|f| f.downcase})
    end
  end

  def self.load_segment(text, annotation, fields = nil)
    if fields.nil?
      start, eend, info = annotation.values_at 0,1,2
      info = JSON.parse(info)
    else
      start, eend = annotation.values_at 0,1
      info = Misc.process_to_hash(fields) do |fields| annotation.values_at *fields.collect{|f| f.downcase} end
    end

    Segment.load(text, start, eend, info, docid)
  end

  def self.tsv(segments, fields = nil)
    tsv = TSV.new({}, :list, :key => "ID", :fields => %w(Start End))
    if fields.nil?
      tsv.fields += ["Info"]
    else
      tsv.fields += fields
    end

    segments.each{|segment| tsv[segment.id] = Document.save_segment(segment, fields) unless segment.offset.nil?}

    tsv
  end


  #{{{ PERSISTENCE

  TSV_REPOS = {}
  FIELDS_FOR_ENTITY_PERSISTENCE = {}
  def self.persist(entity, fields = nil)

    if not fields.nil?
      fields = [fields] if not Array === fields
      fields = fields.collect{|f| f.to_s}
      FIELDS_FOR_ENTITY_PERSISTENCE[entity.to_s] = fields unless fields.nil?
    end

    self.class_eval <<-EOC
      def load_with_persistence_#{entity}
        fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]

        annotations = Persistence.persist("#{ entity }", :Entity, :tsv,
                        :persistence_dir => @persistence_dir) do

          tsv = TSV.new({}, :list, :key => "ID", :fields => %w(Start End))
          if fields.nil?
            tsv.fields += ["Info"]
          else
            tsv.fields += fields
          end

          segments = produce_#{entity}
          segments.each{|segment| tsv[segment.id] = Document.save_segment(segment, fields) unless segment.offset.nil?}

          tsv
        end

        annotations.collect{|id, annotation| Document.load_segment(text, annotation, fields)}
      end
          EOC
  end

  def self.persist_in_tsv(entity, tsv, fields = nil)
    TSV_REPOS[entity.to_s] = tsv

    if not fields.nil?
      fields = [fields] if not Array === fields
      fields = fields.collect{|f| f.to_s}
      FIELDS_FOR_ENTITY_PERSISTENCE[entity.to_s] = fields unless fields.nil?
    end

    self.class_eval <<-EOC
      def load_with_persistence_#{entity}
        fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]

        if not TSV_REPOS["#{ entity }"].include? "#{ entity }"
          tsv = TSV.new({}, :list, :key => "ID", :fields => %w(Start End))
          if fields.nil?
            tsv.fields += ["Info"]
          else
            tsv.fields += fields
          end

          produce_#{entity}.each{|segment| tsv[segment.id] = Document.save_segment(segment, fields) unless segment.offset.nil?}
          TSV_REPOS["#{ entity }"].write
          TSV_REPOS["#{ entity }"]["#{entity}"] = tsv
          TSV_REPOS["#{ entity }"].read
        end

        annotations = TSV_REPOS["#{ entity }"]["#{entity}"]

        annotations.collect{|id, annotation| Document.load_segment(text, annotation, fields)}
      end
      EOC
  end
  
  def self.persist_in_global_tsv(entity, tsv, fields = nil, doc_field = "Document ID", entity_field = "Entity Type")
    TSV_REPOS[entity.to_s] = tsv

    if not fields.nil?
      fields = [fields] if not Array === fields
      fields = fields.collect{|f| f.to_s}
      FIELDS_FOR_ENTITY_PERSISTENCE[entity.to_s] = fields unless fields.nil?
    end

    self.class_eval <<-EOC
      def load_with_persistence_#{entity}
        fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]

        if not TSV_REPOS["#{ entity }"].include? "#{ entity }"
          tsv = TSV.new({}, :list, :key => "ID", :fields => %w(Start End))
          if fields.nil?
            tsv.fields += ["Info"]
          else
            tsv.fields += fields
          end

          produce_#{entity}.each{|segment| tsv[segment.id] = Document.save_segment(segment, fields) unless segment.offset.nil?}

          tsv.add_field "#{ doc_field }" do
            @docid
          end

          tsv.add_field "#{ entity_field }" do
            "#{ entity }"
          end

          TSV_REPOS["#{ entity }"].write
          TSV_REPOS["#{ entity }"].merge!(tsv)
          TSV_REPOS["#{ entity }"].read
        end

        data = TSV_REPOS["#{ entity }"]
        data.filter
        data.add_filter("field:#{ doc_field }", @docid)
        data.add_filter("field:#{ entity_field }", "#{ entity }")

        segments = []
        data.each{|id, annotation| segments << Document.load_segment(text, annotation, fields)}

        data.pop_filter
        data.pop_filter

        segments
      end
      EOC
  end


  def self.define(entity, &block)
    send :define_method, "produce_#{entity}", &block

    self.class_eval <<-EOC
      def load_#{entity}
        return if annotations.include? "#{ entity }"
        if self.respond_to?("load_with_persistence_#{entity}") and not @persistence_dir.nil?
          annotations["#{entity}"] = load_with_persistence_#{entity}
        else
          annotations["#{ entity }"] = produce_#{entity}
        end
      end

      def #{entity}
        begin
          entities = annotations["#{ entity }"]
          if entities.nil?
            load_#{entity}
            entities = annotations["#{ entity }"]
          end
        end

        entities
      end

      def #{entity}_at(pos)
        segment_index("#{ entity }")[pos]
      end

    EOC
  end

  def segment_index(name)
    @segment_indeces[name] ||= Segment.index(self.send(name), persistence_dir.nil? ? :memory : File.join(persistence_dir, name))
  end

  def load_into(segment, *annotations)
    options = annotations.pop if Hash === annotations.last
    options ||= {}
    if options[:persist] and not @persistence_dir.nil?
      persistence_dir = File.join(@persistence_dir, 'ranges')
    else
      persistence_dir = nil
    end

    segment.extend Annotated
    segment.annotations ||= {}
    annotations.collect do |name|
      name = name.to_s
      annotations = segment_index(name)[segment.range]
      segment.annotations[name] = annotations
      class << segment
        self
      end.class_eval "def #{ name }; @annotations['#{ name }']; end"
    end
  end
end
