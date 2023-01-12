require 'rbbt/segment'
require 'rbbt/segment/annotation'

module NamedEntity
  extend Entity
  include Segment
  include SegmentAnnotation

  self.annotation :entity_type, :code, :score

  def entity_type
    annotation_values[:entity_type] || annotation_values[:type]
  end

  def report
    <<-EOF
String: #{ self }
Offset: #{ offset.inspect }
Type: #{entity_type.inspect}
Code: #{code.inspect}
Score: #{score.inspect}
    EOF
  end

  def html
    title = code.nil? ? entity_type : [entity_type, code].compact * " - "

    text = <<-EOF
<span class='Entity'\
#{entity_type.nil? ? "" : " attr-entity-type='#{Array === entity_type ? entity_type * " " : entity_type}'"}\
#{code.nil?  ? "" : " attr-entity-code='#{Array === code ? code * " " : code}'"}\
#{score.nil? ? "" : " attr-entity-score='#{Array === score ? score * " " : score}'"}\
#{segid.nil? ? "" : " attr-segid='#{segid}'"}\
#{title.nil? ? "" : " title='#{Array === title ? title * " " : title}'"}\
>#{ self }</span>
    EOF
    text.chomp
  end

  def entity(params = nil)
    code = self.code || self.dup
    format, entity = code.split(":")
    entity, format = format, nil if entity.nil?

    if defined?(Entity) && Entity.formats.include?(entity_type) or Entity.formats.include?(format)
      params ||= {}
      params[:format] = format if format and params[:format].nil?
      mod = (Entity.formats[entity_type] || Entity.format[entity])
      mod.setup(entity, params)
    end

    entity
  end

end
