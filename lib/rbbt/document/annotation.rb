require 'rbbt/segment'
require 'rbbt/segment/annotation'

module Document
  def self.define(type, &block)
    send :property, type do 
      segments = self.instance_exec &block

      Segment.align(self, segments) unless segments.empty? || (Segment === segments && segments.offset) || (Segment === segments.first && segments.first.offset)

      segments.each do |segment|
        SegmentAnnotation.setup(segment, :type => type.to_s) unless SegmentAnnotation === segment && segment.type
      end

      docid = self.docid
      segments.each{|s| s.docid = docid if s.docid.nil? }

      segments
    end
  end

  def self.define_multiple(type, &block)
    send :property, type => :multiple do |list|
      doc_segments = self.instance_exec list, &block

      doc_segments = doc_segments.chunked_values_at(list) if Hash === doc_segments

      doc_segments.each_with_index do |segments,i|
        next if segments.nil?
        document = list[i]
        Segment.align(document, segments) unless segments.nil? || segments.empty? || (Segment === segments && segments.offset) || (Segment === segments.first && segments.first.offset)

        segments.each do |segment|
          SegmentAnnotation.setup(segment, :type => type.to_s) unless SegmentAnnotation === segment && segment.type
        end

        docid = document.docid

        segments.each{|s| s.docid = docid if s.docid.nil? }

        segments
      end
    end
  end
end
