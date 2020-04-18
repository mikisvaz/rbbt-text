require 'rbbt/segment'
require 'rbbt/segment/named_entity'
require 'rbbt/segment/segmented'

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
    when (Segmented === text and protect)
      entities(text.split_segments(true), protect, *args)
    else
      match(text, *args)
    end
  end
end


