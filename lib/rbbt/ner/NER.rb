require 'rbbt/ner/annotations'

class NER
  def entities(text, overlap = true)
    case
    when Array === text
      text.collect do |element|
        matches = entities(element, overlap)
        matches.each{|match|
          match.offset += element.offset
        }
        matches
      end.flatten
    when (Annotated === text and not overlap)
      entities(text.split)
    else
      match(text)
    end
  end
end


