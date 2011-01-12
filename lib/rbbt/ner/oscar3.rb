require 'rbbt'
require 'rjb'
require 'libxml'
require 'rbbt/ner/annotations'
require 'rbbt/ner/NER'
require 'rbbt/util/log'

class OSCAR3 < NER
  Rbbt.add_software "OSCAR3" => ['','']

  @@TextToSciXML   = Rjb::import('uk.ac.cam.ch.wwmm.ptclib.scixml.TextToSciXML')
  @@ProcessingDocumentFactory   = Rjb::import('uk.ac.cam.ch.wwmm.oscar3.recogniser.document.ProcessingDocumentFactory')
  @@MEMMSingleton = Rjb::import('uk.ac.cam.ch.wwmm.oscar3.recogniser.memm.MEMMSingleton')
  @@DFANEFinder = Rjb::import('uk.ac.cam.ch.wwmm.oscar3.recogniser.finder.DFANEFinder')
  @@MEMM = @@MEMMSingleton.getInstance();
  @@DFA  = @@DFANEFinder.getInstance();

  def self.match(text,  type = nil, memm =  true)
    doc  = @@ProcessingDocumentFactory.getInstance().makeTokenisedDocument(@@TextToSciXML.textToSciXML(text), true, false, false);
    mentions = []
    it = doc.getTokenSequences().iterator

    reconizer = memm ? @@MEMM : @@DFA
    type = [type] unless type.nil? or Array === type
    pos = 0
    while it.hasNext do 
      Log.debug "OSCAR3: Finding mentions in sequence #{pos += 1}"
      sequence = it.next
      entities = @@MEMM.findNEs(sequence, text)

      keys = entities.keySet.iterator
      while keys.hasNext do
        key = keys.next
        mention_type, rstart, rend, mention = key.to_string.match(/\[NE:(.*):(.*):(.*):(.*)\]/).values_at(1,2,3,4)
        next unless type.nil? or type.include? mention_type
        score  = entities.get(key)

        NamedEntity.annotate mention, rstart, mention_type, nil, score.to_string.to_f
        
        mentions << mention
      end
    end

    mentions
  end

  def match(*args)
    OSCAR3.match *args
  end
end



