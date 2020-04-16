require 'rbbt/text/segment'
require 'rbbt/text/segment/segmented'
require 'rbbt/text/segment/docid'
require 'rbbt/tsv'
require 'rbbt/resource/path'
require 'rbbt/persist/tsv'
require 'rbbt/util/misc'
require 'rbbt/text/document'
require 'json'

class Corpus
  class Document
    
    class MultipleEntity < Exception; end

    attr_accessor :text, :docid, :namespace, :id, :type, :hash, :segments, :segment_indices, :persist_dir, :global_persistence, :corpus

    attr_accessor :multiple_result

    def initialize(persist_dir = nil, docid = nil, text = nil, global_persistence = nil, corpus = nil)
      @segments = {}
      @segment_indices = {}
      @corpus = corpus

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

    def self.define(entity, &block)
      send :define_method, "produce_#{entity}" do 
        segments = self.instance_exec &block

        segments.each{|s| s.docid = docid }
      end

      self.class_eval <<-EOC, __FILE__, __LINE__ + 1
        def load_#{entity}(raw = false)
          return if segments.include? "#{ entity }"
          if self.respond_to?("load_with_persistence_#{entity}") and not @persist_dir.nil?
            entities = load_with_persistence_#{entity}(raw)
          else
            entities = produce_#{entity}
          end

          segments["#{ entity }"] = entities
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

    def self.define_multiple(entity, &block)
      send :define_method, "produce_#{entity}" do
        if self.multiple_result && self.multiple_result[entity]
          segments = self.multiple_result[entity]
          return segments.each{|s| s.docid = docid }
        end
        raise MultipleEntity, "Entity #{entity} runs with multiple documents, please prepare beforehand with prepare_multiple: #{self.docid}"
      end

      name = "multiple_produce_#{entity}"
      class << self
        self
      end.send :define_method, name, &block

      self.class_eval <<-EOC, __FILE__, __LINE__ + 1
        def load_#{entity}(raw = false)
          return if segments.include? "#{ entity }"
          if self.respond_to?("load_with_persistence_#{entity}") and not @persist_dir.nil?
            entities = load_with_persistence_#{entity}(raw)
          else
            entities = produce_#{entity}
          end

          segments["#{ entity }"] = entities
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

    def self.prepare_multiple(docs, entity)
      missing = []
      docs.each do |doc|
        begin
          doc.send(entity)
        rescue MultipleEntity
          missing << doc
        end
      end
      res = self.send("multiple_produce_#{entity.to_s}", missing) if missing.any?
      case res
      when Array
        res.each_with_index do |res,i|
          missing[i].multiple_result ||= {}
          missing[i].multiple_result[entity] = res
        end
      when Hash
        res.each do |document,res|
          case document
          when Corpus::Document
            document.multiple_result[entity] = res
          when String
            document = missing.select{|d| d.docid == document}.first
            document.multiple_result[entity] = res
          end
        end
      end
      missing.each{|doc|
        doc.send entity 
      }
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

      self.class_eval <<-EOC, __FILE__, __LINE__
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
      tsv = TSV.setup(Persist.open_tokyocabinet(tsv, false, :list), :key => "ID", :fields => ["Start", "End", "JSON", "Document ID", "Entity Type"]).tap{|t| t.unnamed = true, t.close} if Path === tsv

      if ! tsv.nil? && ! tsv.respond_to?(:keys)
        fields = tsv
        tsv = nil
      end

      TSV_REPOS[entity.to_s] = tsv

      if ! fields.nil?
        fields = [fields] if not Array === fields
        fields = fields.collect{|f| f.to_s}
        FIELDS_FOR_ENTITY_PERSISTENCE[entity.to_s] = fields unless fields.nil?
      end

      self.class_eval <<-EOC, __FILE__, __LINE__ + 1
        def load_with_persistence_#{entity}(raw = false)
          repo = TSV_REPOS["#{ entity }"]
          if repo.nil?
            raise "No persistence file or persistence dir for persist_in_tsv" if persist_dir.nil?
            repo = Persist.open_tokyocabinet(persist_dir.annotations_by_type.find, true, :marshal_tsv)
          end

          fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]
          begin
            if ! repo.include?("#{ entity }")
              segments = produce_#{entity}
              repo.write_and_read do
                repo["#{entity}"] = Segment.tsv(segments, fields) if segments.any?
              end
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
          ensure
            repo.close
          end
        end
      EOC
    end
    
    def self.persist_in_global_tsv(entity, tsv = nil, fields = nil, doc_field = nil, entity_field = nil)
      tsv = TSV.setup(Persist.open_tokyocabinet(tsv, false, :list), :key => "ID", :fields => (fields || ["Start", "End", "JSON", "Document ID", "Entity Type"])).tap{|t| t.unnamed = true, t.close} if Path === tsv

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

      self.class_eval <<-EOC, __FILE__, __LINE__ + 1
        def load_with_persistence_#{entity}(raw = false)
          fields = FIELDS_FOR_ENTITY_PERSISTENCE["#{ entity }"]

          data = TSV_REPOS["#{ entity }"] || @global_persistence
          
          begin

            if data.respond_to? :persistence_path and String === data.persistence_path
              data.filter(data.persistence_path + '.filters')
            end

            keys = data.read_and_close do

              fields = data.fields if fields.nil? and data.respond_to? :fields

              data.add_filter("field:#{ doc_field }", @docid) if fields.include?("#{doc_field}")
              data.add_filter("field:#{ entity_field }", "#{ entity }") if fields.include?("#{entity_field}")
              keys = data.keys
              data.pop_filter if fields.include?("#{entity_field}")
              data.pop_filter if fields.include?("#{doc_field}")

              keys
            end


            if keys.empty?
              segments = produce_#{entity}
              segments << Segment.setup("No #{entity} found in document " + @docid.to_s, -1) if segments.empty?
              tsv = Segment.tsv(segments, *fields.reject{|f| ["#{doc_field}", "#{entity_field}", "Start", "End", "annotation_types"].include? f})

              tsv.add_field "#{ doc_field }" do
                @docid
              end

              tsv.add_field "#{ entity_field }" do
                "#{ entity }"
              end

              keys = data.write_and_close do
                data.add_filter("field:#{ doc_field }", @docid) if fields.include?("#{doc_field}")
                data.add_filter("field:#{ entity_field }", "#{ entity }") if fields.include?("#{entity_field}")
                keys = tsv.collect do |key, value|
                  data[key] = value
                  key
                end
                data.pop_filter if fields.include?("#{entity_field}")
                data.pop_filter if fields.include?("#{doc_field}")
                keys
              end

            else
              return nil if raw == :check
            end

            return data.values if raw

            start_pos = data.identify_field "Start"
            data.read_and_close do 
              data.chunked_values_at(keys).collect{|annotation| 
                  begin
                pos = annotation[start_pos]
                Segment.load_tsv_values(text, annotation, fields) unless [-1, "-1", [-1], ["-1"]].include?(pos)
                  rescue
                    Log.exception $!
                    iif keys
                    iif [text, annotation]
                  end
                  
              }.compact
            end
          ensure
            data.close
          end

        end
        EOC
    end

    def segment_index(name, persist_dir = nil)
      @segment_indices[name] ||= Segment.index(self.send(name), persist_dir.nil? ? :memory : File.join(persist_dir, name + '.range'))
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
        segment.segments[name] ||= {}
        segment.segments[name] = annotations
        class << segment
          self
        end.class_eval "def #{ name }; @segments['#{ name }']; end", __FILE__, __LINE__ + 1
      end

      segment
    end

    def entity
      Object::Document.setup(self.docid, corpus)
    end
  end
end
