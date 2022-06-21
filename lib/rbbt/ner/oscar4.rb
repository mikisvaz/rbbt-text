require 'rbbt'
require 'rjb'
require 'rbbt/segment'
require 'rbbt/ner/NER'
require 'rbbt/util/log'

class OSCAR4 < NER
  Rbbt.claim Rbbt.software.opt.OSCAR4, :install, Rbbt.share.install.software.OSCAR4.find

  def self.init

    # There is an incompatibility between the OpenNLP version in OSCAR4 and the
    # one used for other matters in Rbbt, which is the most recent. We remove
    # the standalone jars from the CLASSPATH
    ENV["CLASSPATH"] = ENV["CLASSPATH"].split(":").select{|p| p !~ /opennlp/} * ":"

    Rjb::load(nil, jvmargs = ['-Xms1G','-Xmx2G']) unless Rjb.loaded?

    @@OSCAR      ||= Rjb::import('uk.ac.cam.ch.wwmm.oscar.Oscar')
    @@FormatType ||= Rjb::import('uk.ac.cam.ch.wwmm.oscar.chemnamedict.entities.FormatType')
  end

  def self.tagger
    @@tagger ||= @@OSCAR.new()
  end

  def self.match(text, protect = false,  type = nil)
    self.init

    return [] if text.nil? or text.strip.empty?

    oscar = tagger
    #entities = oscar.findAndResolveNamedEntities(text);
    entities = oscar.findNamedEntities(text);
    it = entities.iterator

    result = []

    while it.hasNext
      entity = it.next
      mention = entity.getSurface
      #inchi = entity.getFirstChemicalStructure(@@FormatType.INCHI)
      #inchi = inchi.getValue() unless inchi.nil?
      inchi = nil

      next unless entity.getType.toString == type unless type.nil?

      NamedEntity.setup mention, :offset => entity.getStart, :entity_type => entity.getType, :code => inchi, :score => entity.getConfidence

      result << mention
    end

    result
  end

  def match(*args)
    OSCAR4.match *args
  end
end



