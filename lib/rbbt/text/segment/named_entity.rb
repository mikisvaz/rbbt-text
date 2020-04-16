require 'rbbt/text/segment'
require 'rbbt/entity'

module NamedEntity 
  extend Entity
  include Segment

  self.annotation :type, :code, :score

  def report
    <<-EOF
String: #{ self }
Offset: #{ offset.inspect }
Type: #{type.inspect}
Code: #{code.inspect}
Score: #{score.inspect}
    EOF
  end

  def html
    text = <<-EOF
<span class='Entity'\
#{type.nil? ? "" : " attr-entity-type='#{Array === type ? type * " " : type}'"}\
#{code.nil?  ? "" : " attr-entity-code='#{Array === code ? code * " " : code}'"}\
#{score.nil? ? "" : " attr-entity-score='#{Array === score ? score * " " : score}'"}\
>#{ self }</span>
    EOF
    text.chomp
  end

  def entity(params = nil)
    code = self.dup
    format, entity = code.split(":")
    entity, format = format, nil if entity.nil?
    
    if defined?(Entity) && Entity.formats.include?(type) or Entity.formats.include?(format)
      params ||= {}
      params[:format] = format if format and params[:format].nil?
      mod = (Entity.formats[type] || Entity.format[entity])
      mod.setup(entity, params)
    end

    entity
  end

end

