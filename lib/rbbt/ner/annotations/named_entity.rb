require 'rbbt/ner/annotations'

module NamedEntity 
  include Segment
  attr_accessor :type, :code, :score

  def self.annotate(string, offset = nil, type = nil, code = nil, score = nil)
    string.extend NamedEntity
    string.offset = offset
    string.type  = type
    string.code  = code
    string.score = score
    string
  end

  def to_s
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
#{type.nil? ? "" : " attr-entity-type='#{type}'"}\
#{code.nil?  ? "" : " attr-entity-type='#{Array === code ? code * " " : code}'"}\
#{score.nil? ? "" : " attr-entity-type='#{Array === score ? score * " " : score}'"}\
>#{ self }</span>
    EOF
    text.chomp
  end
end

