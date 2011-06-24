require 'rbbt/util/tsv'
require 'rbbt/util/misc'
require 'json'


class Document

  attr_accessor :text, :annotations, :annotation_indeces, :persistence_dir
  def initialize(persistence_dir = nil)
    @annotations = {}
    @annotation_indeces = {}
    @persistence_dir = persistence_dir unless persistence_dir.nil?
  end

  def self.save_segment(segment)
    [segment.offset, segment.end, segment.info.to_json]
  end

  def self.load_segment(text, annotation)
    start, eend, info = annotation.values_at 0,1,2
    info = JSON.parse(info)
    Segment.load(text, start, eend, info)
  end

  def self.persist(entity)
    self.class_eval <<-EOC
      def load_with_persistence_#{entity}

        annotations = Persistence.persist("#{ entity }", :Entity, :tsv,
                        :persistence_dir => @persistence_dir) do

          tsv = TSV.new({}, :list, :key => "ID", :fields => %w(Start End Info))
          tsv.type = :list
          produce_#{entity}.each{|segment| tsv[segment.id] = Document.save_segment(segment) unless segment.offset.nil?}
          tsv

        end

        annotations.collect{|id, annotation| Document.load_segment(text, annotation)}
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
    EOC
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
      @annotation_indeces[name] ||= Segment.index(self.send(name), persistence_dir.nil? ? :memory : File.join(persistence_dir, name))
      annotations = @annotation_indeces[name][segment.range]
      segment.annotations[name] = annotations
      class << segment
        self
      end.class_eval "def #{ name }; @annotations['#{ name }']; end"
    end
  end
end
