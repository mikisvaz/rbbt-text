require 'rbbt/ner/segment'

module Relationship
  extend Annotation
  self.annotation :segment
  self.annotation :terms
  self.annotation :type

  def text
    if segment
      segment
    else
      type + ": " + terms * ", "
    end
  end

  def html
    text = <<-EOF
<span class='Relationship'\
>#{ self.text }</span>
    EOF
    text.chomp
  end
end
