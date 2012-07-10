require 'rbbt/ner/segment'
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
end

