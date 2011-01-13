require 'rbbt/ner/annotations'

class NER
  def entities(text, overlap = true, *args)
    case
    when Array === text
      text.collect do |element|
        matches = entities(element, overlap, *args)
        matches.each{|match|
          match.offset += element.offset if match.offset
        }
        matches
      end.flatten
    when (Annotated === text and not overlap)
      entities(text.split, overlap, *args)
    else
      match(text, *args)
    end
  end
end


