require 'rbbt/ner/annotations/named_entity'
class Corpus
  def find_entities_in_docs(entity, doc_ids = nil, noload = false)
    case
    when doc_ids.nil?
      docs = find
    when String === doc_ids
      docs = find(doc_ids)
    when Array === doc_ids
      docs = doc_ids.collect{|docid| find_docid(docid)}.flatten
    end

    docs.collect{|doc| doc.find_entities(entity, noload)}.flatten
  end

  def self.define_entity_ner(entity, sentence, method_name = nil, &block)
    method_name = entity.downcase.to_sym if method_name.nil?

    if sentence
      Sentence::ENTITIES[entity] = block
      Sentence.send(:define_method, method_name){find_entities(entity)}
    else
      Document::ENTITIES[entity] = block
    end
    Corpus.send(:define_method, method_name){find_entities_in_docs(entity)}
    Document.send(:define_method, method_name){find_entities(entity)}
    Corpus.send(:define_method, "produde_#{method_name}"){find_entities_in_docs(entity, nil, true)}
    Document.send(:define_method, "produce_#{method_name}"){find_entities(entity, true)}
    Document.send(:define_method, "#{ method_name }_at"){|pos| annotations_at(pos, entity)} 
  end
end

class Document
  ENTITIES = {} unless defined? ENTITIES

  def find_entities_in_sentence(entity)
    sentences.collect{|sentence|
      entities = self.annotations_at(sentence.range, entity)
      if entities.empty?
        entities = Sentence.new(sentence).find_entities(entity).collect{|found|
          found.pull(sentence.offset)
          found
        }
      end
      entities
    }.flatten
  end

  def find_entities(entity, noload = false)
    corpus.add_annotations(docid, entity, noload) do
      if ENTITIES.include? entity
        ENTITIES[entity].call self
      else
        find_entities_in_sentence(entity)
      end.collect{|found| found.docid = docid; found}
    end
  end
end

class Sentence
  ENTITIES = {} unless defined? ENTITIES

  attr_accessor :entity_cache

  def find_entities(entity)
    @entity_cache ||= {}
    if @entity_cache.include? entity
      return @entity_cache[entity]
    else
      @entity_cache = ENTITIES[entity].call self
    end
  end
end
