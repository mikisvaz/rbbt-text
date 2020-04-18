#module Segment
#
#  def self.set_tsv_fields(fields, segments)
#    tsv_fields = []
#    add_types = ! (fields.delete(:no_types) || fields.delete("no_types") || fields.include?(:JSON) || fields.include?("JSON"))
#    literal = (fields.delete(:literal) || fields.delete("literal"))
#    tsv_fields << "Start" << "End"
#    tsv_fields << :annotation_types if add_types
#    tsv_fields << :literal if literal
#
#    if fields.any? and not (fields == [:all] or fields == ["all"])
#      tsv_fields.concat fields 
#    else
#      tsv_fields.concat segments.first.annotations if segments.any?
#    end
#    tsv_fields
#    tsv_fields.collect!{|f| f.to_s}
#    tsv_fields.delete "offset"
#    tsv_fields
#  end
#
#  def self.tsv(segments, *fields)
#    fields = set_tsv_fields fields, segments
#    tsv = TSV.setup({}, :key_field => "ID", :fields => fields, :type => :double)
#
#    segments.each do |segment|
#      tsv[segment.segment_id] = self.tsv_values_for_segment(segment, fields)
#    end
#
#    tsv
#  end
#
#  def self.load_tsv(tsv)
#    fields = tsv.fields
#    tsv.with_unnamed do
#      tsv.collect do |id, values|
#        Annotated.load_tsv_values(id, values, fields)
#      end
#    end
#  end
#end
