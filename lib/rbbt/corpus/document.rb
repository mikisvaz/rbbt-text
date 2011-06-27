require 'rbbt/ner/annotations'
require 'rbbt/util/tsv'
require 'rbbt/util/resource'
require 'rbbt/util/misc'
require 'json'

class Document

  attr_accessor :text, :docid, :namespace, :id, :type, :hash, :annotations, :segment_indeces, :persistence_dir, :global_persistence
  def initialize(persistence_dir = nil, docid = nil, text = nil, global_persistence = nil)
    @annotations = {}
    @segment_indeces = {}

    if not persistence_dir.nil?
      @persistence_dir = persistence_dir
      @persistence_dir = Resource::Path.path(@persistence_dir) if not Resource::Path == @persistence_dir
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

  def self.save_segment(segment, fields = nil)
    if fields.nil?
      eend = case segment.offset; when nil; nil; when -1; -1; else segment.end; end
      [segment.offset, eend, segment.info.to_json]
    else
      eend = case segment.offset; when nil; nil; when -1; -1; else segment.end; end
      info = segment.info
      info["literal"] = segment.to_s.gsub(/\s/,' ')
      info.extend IndiferentHash
      [segment.offset, eend].concat info.values_at(*fields.collect{|f| f.downcase}).collect{|v| Array === v ? v * "|" : v}
    end
  end

  def self.load_segment(text, annotation, fields = nil)
    if fields.nil?
      start, eend, info = annotation.values_at 0,1,2
      info = JSON.parse(info)
    else
      start, eend = annotation.values_at 0,1
      info = Misc.process_to_hash(fields) do |fields| annotation.values_at(*fields.collect{|f| f.downcase}).collect{|v| v.index("|").nil? ? v : v.split("|")} end
    end

    Segment.load(text, start, eend, info, @docid)
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

        annotations = Persistence.persist("#{ entity }", :Entity, :tsv_string,
                        :persistence_file => File.join(@persistence_dir, "#{ entity }")) do

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
      def load_with_persistence_#{entity}
        repo = TSV_REPOS["#{ entity }"]
        if repo.nil?
          raise "No persistence file or persistencr dir for persist_in_tsv" if persistence_dir.nil?
          repo = TCHash.get(persistence_dir.annotations_by_type.find, TCHash::TSVSerializer)
        end


        fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]

        if not repo.include? "#{ entity }"
          tsv = TSV.new({}, :list, :key => "ID", :fields => %w(Start End))
          if fields.nil?
            tsv.fields += ["Info"]
          else
            tsv.fields += fields
          end

          produce_#{entity}.each{|segment| tsv[segment.id] = Document.save_segment(segment, fields) unless segment.offset.nil?}
          repo.write
          repo["#{entity}"] = tsv
          repo.read
        end

        annotations = repo["#{entity}"]

        annotations.collect{|id, annotation| Document.load_segment(text, annotation, fields)}
      end
      EOC
  end
  
  def self.persist_in_global_tsv(entity, tsv = nil, fields = nil, doc_field = nil, entity_field = nil)
    if not tsv.nil? and not tsv.respond_to?(:keys)
      entity_field = doc_field if doc_field
      doc_field = fields if fields
      fields = tsv if tsv
      tsv = nil
    end

    doc_field ||= "Document ID" 
    entity_field ||= "Entity Type"

    TSV_REPOS[entity.to_s] = tsv

    if not fields.nil?
      fields = [fields] if not Array === fields
      fields = fields.collect{|f| f.to_s}
      FIELDS_FOR_ENTITY_PERSISTENCE[entity.to_s] = fields unless fields.nil?
    end

    self.class_eval <<-EOC
      def load_with_persistence_#{entity}
        fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]

        data = TSV_REPOS["#{ entity }"]

        if data.nil?
          data = global_persistence
        end

        data.filter
        data.add_filter("field:#{ doc_field }", @docid)
        data.add_filter("field:#{ entity_field }", "#{ entity }")

        if data.keys.empty?
          tsv = TSV.new({}, :list, :key => "ID", :fields => %w(Start End))
          if fields.nil?
            tsv.fields += ["Info"]
          else
            tsv.fields += fields
          end

          segments = produce_#{entity}
          segments << Segment.annotate("No #{entity} found in document #{ @docid }", -1) if segments.empty?
          segments.each{|segment| tsv[segment.id] = Document.save_segment(segment, fields) unless segment.offset.nil?}

          tsv.add_field "#{ doc_field }" do
            @docid
          end

          tsv.add_field "#{ entity_field }" do
            "#{ entity }"
          end

          data.write
          data.merge!(tsv)
          data.read
        end

        segments = []
        data.each{|id, annotation| segments << Document.load_segment(text, annotation, fields) unless annotation[1].to_i == -1}

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

      def #{entity}_at(pos, persist = false)
        segment_index("#{ entity }", persist ? File.join(@persistence_dir, 'ranges') : nil)[pos]
      end

    EOC
  end

  def segment_index(name, persistence_dir = nil)
    @segment_indeces[name] ||= Segment.index(self.send(name), persistence_dir.nil? ? :memory : File.join(persistence_dir, name + '.range'))
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
      annotations = segment_index(name, persistence_dir)[segment.range]
      segment.annotations[name] = annotations
      class << segment
        self
      end.class_eval "def #{ name }; @annotations['#{ name }']; end"
    end

    segment
  end
end
