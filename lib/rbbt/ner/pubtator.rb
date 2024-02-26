
require 'rbbt/segment'
require 'rbbt/segment/named_entity'
require 'rbbt/segment/transformed'
require 'rbbt/text/misc'
require 'rest-client'
module Pubtator
  PUBTATOR_URL="https://www.ncbi.nlm.nih.gov/research/pubtator-api/publications/export/pubtator"

  def self.pubtator_entities(pmids, concepts = ['gene'], alignments = nil)

    texts = {}
    entities = {}

    last = nil
    Misc.chunk(pmids, 1000) do |chunk|
      time = Time.now
      if last
        diff = time - last
        if diff < 3
          sleep(3 - diff)
        end
      end
      last = time

      response = RestClient.post(PUBTATOR_URL, {pmids: chunk, concepts: concepts}.to_json, {content_type: 'json', accept: 'json'}).body
      response.split("\n").each do |line|
        next if line.empty?
        if line =~ /^\d+\|/
          pmid, text_type, content = line.split("|")
          texts[pmid] ||= []
          texts[pmid] << content
        else
          pmid, start, eend, literal, type, code = line.split("\t")
          ne = NamedEntity.setup(literal, code: code, type: type, offset: start.to_i)
          entities[pmid] ||= [] 
          entities[pmid] << ne 
        end
      end
    end

    if alignments
      new_entities = {}
      entities.each do |pmid,list|
        text = texts[pmid] * " "
        alignment = alignments[pmid]
        raise "Alignment for #{pmid} not found" if alignment.nil?
        greek_characters = Misc.greek_characters
        new_list = Transformed.with_transform(alignment, greek_characters.keys, lambda{|k| greek_characters[k] }) do
          list.collect do |entity|
            begin
              Segment.relocate(entity, text, alignment, 10)
              entity
            rescue Exception
              Log.low "Entity #{entity} (#{entity.range}) not found in alignment text for #{pmid}"
              next
            end
          end
        end
        new_entities[pmid] = new_list.compact
      end
      entities = new_entities
    end

    entities
  end
end
