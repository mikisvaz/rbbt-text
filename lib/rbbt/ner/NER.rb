require 'rbbt/ner/annotations'
require 'rbbt/ner/annotations/named_entity'

class NER
  def entities(text, protect = false, *args)
    case
    when Array === text
      text.collect do |element|
        matches = entities(element, protect, *args)
        matches.each{|match|
          match.offset += element.offset if match.offset and element.offset
        }
        matches
      end.flatten
    when (Annotated === text and protect)
      entities(text.split_segments(true), protect, *args)
    else
      match(text, *args)
    end
  end
end


