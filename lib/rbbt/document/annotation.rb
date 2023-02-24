require 'rbbt/segment'
require 'rbbt/segment/annotation'

module Document
  def self.define(type, &block)
    send :property, type do 
      segments = self.instance_exec &block

      Segment.align(self, segments) unless segments.empty? || 
          (Segment === segments && segments.offset) || 
          (Array === segments && Segment === segments.first && segments.first.offset)

      segments.each do |segment|
        SegmentAnnotation.setup(segment, :type => type.to_s) unless SegmentAnnotation === segment && segment.type
      end

      docid = self.docid
      segments.each{|s| s.docid = docid }

      segments
    end

    DocID.property type do
      self.document.send(type)
    end

    SegID.property type do
      self.overlaps(self.docid.send(type))
    end

    Segment.property type do
      self.overlaps(self.docid.send(type))
    end

    seg_type = "segids_for_" + type.to_s

    send :property, seg_type do 
      SegID.setup(self.send(type).collect{|s| s.segid })
    end

    DocID.property seg_type do
      self.document.send(seg_type)
    end

    SegID.property seg_type do
      self.overlaps(self.docid.send(seg_type))
    end

    Segment.property seg_type do
      self.overlaps(self.docid.send(seg_type))
    end
  end

  def self.define_multiple(type, &block)
    send :property, type => :multiple do |list|
      doc_segments = self.instance_exec list, &block

      doc_segments = doc_segments.chunked_values_at(list) if Hash === doc_segments

      doc_segments.each_with_index do |segments,i|
        next if segments.nil?
        document = list[i]
        Segment.align(document, segments) unless segments.nil? || 
          segments.empty? || 
          (Segment === segments && segments.offset) || 
          (Array === segments && Segment === segments.first && segments.first.offset)

        segments.each do |segment|
          SegmentAnnotation.setup(segment, :type => type.to_s) unless SegmentAnnotation === segment && segment.type
        end

        docid = document.docid

        segments.each{|s| s.docid = docid }

        segments.segid
      end
    end

    DocID.property type do
      self.document.send(type)
    end

    SegID.property type do
      self.overlaps(self.docid.send(type))
    end

    Segment.property type do
      self.overlaps(self.docid.send(type))
    end

    seg_type = "segids_for_" + type.to_s

    send :property, seg_type do 
      SegID.setup(self.send(type).collect{|s| s.segid })
    end

    DocID.property seg_type do
      self.document.send(seg_type)
    end

    SegID.property seg_type do
      self.overlaps(self.docid.send(seg_type))
    end

    Segment.property seg_type do
      self.overlaps(self.docid.send(seg_type))
    end
  end
end
