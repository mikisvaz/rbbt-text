require 'rbbt/segment/named_entity'
require 'rbbt/text/segment/relationship'
module Brat
  Rbbt.claim Rbbt.software.opt.Brat, :install, "https://github.com/nlplab/brat.git"

  def self.load(file)
    entities = {}
    relationships = {}
    entity_ids = {}
    TSV.traverse file, :type => :array do |line|
      id, info, literal = line.split("\t")
      case id[0] 
      when "T"
        type, start, eend = info.split(" ")
        entities[id] = NamedEntity.setup(literal, :offset => start.to_i, :type => type)
      when "#"
        type, id = info.split(" ")
        entities[id].code = literal unless entities[id].nil?
      when "R"
        type, *args = info.split(" ")
        tf, tg = args.collect{|e| e.split(":").last }
        tf = entities[tf]
        tg = entities[tg]
        relationship = Relationship.setup([tf,tg] * "~" + "#" + type, :terms => [tf,tg], :type => type)
        relationships[id] = relationship
      end
    end
    [entities.values, relationships.values]
  end
end
