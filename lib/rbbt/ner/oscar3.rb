require 'rbbt'
require 'rjb'
require 'rbbt/ner/NER'
require 'rbbt/util/log'

class OSCAR3 < NER
  Rbbt.claim Rbbt.software.opt.OSCAR3, :install, Rbbt.share.install.software.OSCAR3.find

  def self.init
    @@TextToSciXML              ||= Rjb::import('uk.ac.cam.ch.wwmm.ptclib.scixml.TextToSciXML')
    @@ProcessingDocumentFactory ||= Rjb::import('uk.ac.cam.ch.wwmm.oscar3.recogniser.document.ProcessingDocumentFactory')
    @@MEMMSingleton             ||= Rjb::import('uk.ac.cam.ch.wwmm.oscar3.recogniser.memm.MEMMSingleton')
    @@DFANEFinder               ||= Rjb::import('uk.ac.cam.ch.wwmm.oscar3.recogniser.finder.DFANEFinder')
    @@MEMM                      ||= @@MEMMSingleton.getInstance();
    @@DFA                       ||= @@DFANEFinder.getInstance();
  end

  def self.match(text,  type = nil, memm =  false)
    self.init
    doc  = @@ProcessingDocumentFactory.getInstance().makeTokenisedDocument(@@TextToSciXML.textToSciXML(text), true, false, false);
    mentions = []
    it = doc.getTokenSequences().iterator

    type = [type] unless type.nil? or Array === type
    while it.hasNext do 
      sequence = it.next

      # Fix sequence offset
      sequence_str = sequence.getSourceString.to_s
      sequence_offset = sequence.offset.to_i
      offset = 0
      while text[(sequence_offset + offset)..(sequence_offset + offset + sequence_str.length - 1)] != sequence_str and
        not offset + sequence_offset + sequence_str.length > text.length

        offset += 1
      end

      next if offset + sequence_offset + sequence_str.length > text.length

      if memm
        entities = @@MEMM.findNEs(sequence, text) 
        keys = entities.keySet.iterator
      else
        entities = @@DFA.getNEs(sequence)
        keys = entities.iterator
      end

      while keys.hasNext do
        key = keys.next
        mention_type, rstart, rend, mention = key.to_string.match(/\[NE:(.*):(.*):(.*):(.*)\]/).values_at(1,2,3,4)
        next unless type.nil? or type.include? mention_type
        score  = memm ? entities.get(key).to_string.to_f : nil

        NamedEntity.setup mention, :offset => rstart.to_i + offset, :entity_type => mention_type, :score => score
        
        mentions << mention unless mentions.collect{|m| m.to_s}.include? mention.to_s
      end
    end

    mentions
  end

  def match(*args)
    OSCAR3.match *args
  end
end



