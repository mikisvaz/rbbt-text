require 'rbbt/ner/annotations'

module NamedEntity 
  include Segment
  attr_accessor :type, :code, :score

  def self.annotate(string, offset = nil, type = nil, code = nil, score = nil)
    string.extend NamedEntity
    string.offset = offset unless offset.nil?
    string.type  = type unless type.nil?
    string.code  = code unless code.nil?
    string.score = score unless score.nil?
    string
  end

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

