require 'rbbt'
require 'rjb'
require 'libxml'
require 'rbbt/ner/segment'
require 'rbbt/ner/NER'
require 'rbbt/util/log'

class OSCAR4 < NER
  Rbbt.claim Rbbt.software.opt.OSCAR4, :install, Rbbt.share.install.software.OSCAR4.find

  Rjb::load(nil, jvmargs = ['-Xms128m','-Xmx2048m'])
  @@OSCAR = Rjb::import('uk.ac.cam.ch.wwmm.oscar.Oscar')

  def self.match(text,  type = nil, memm =  false)

    return [] if text.nil? or text.strip.empty?

    oscar = @@OSCAR.new();
    entities = oscar.findAndResolveNamedEntities(text);
    it = entities.iterator

    result = []

    while it.hasNext
      entity = it.next
      mention = entity.getSurface
      result << mention

      NamedEntity.setup mention, entity.getStart, entity.getType, nil, entity.getNamedEntity.getConfidence
    end

    result
  end

  def match(*args)
    OSCAR4.match *args
  end
end



