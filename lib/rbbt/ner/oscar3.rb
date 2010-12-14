require 'rbbt'
require 'rjb'
require 'libxml'
require 'rbbt/ner/named_entity'
require 'rbbt/util/log'

class OSCAR3
  Rbbt.add_software "OSCAR3" => ['','']

  @@TextToSciXML   = Rjb::import('uk.ac.cam.ch.wwmm.ptclib.scixml.TextToSciXML')
  @@ProcessingDocumentFactory   = Rjb::import('uk.ac.cam.ch.wwmm.oscar3.recogniser.document.ProcessingDocumentFactory')
  @@MEMMSingleton = Rjb::import('uk.ac.cam.ch.wwmm.oscar3.recogniser.memm.MEMMSingleton')
  @@MEMM = @@MEMMSingleton.getInstance();

  def initialize
  end

  def extract(text, type = "CM")
    Log.debug "OSCAR3: Finding mentions in #{text}"
    doc  = @@ProcessingDocumentFactory.getInstance().makeTokenisedDocument(@@TextToSciXML.textToSciXML(text), true, false, false);
    mentions = []
    it = doc.getTokenSequences().iterator
    while it.hasNext do 
      entities = @@MEMM.findNEs(it.next, text)

      keys = entities.keySet.iterator
      while keys.hasNext do
        key = keys.next
        type, rstart, rend, mention = key.to_string.match(/\[NE:(.*):(.*):(.*):(.*)\]/).values_at(1,2,3,4)
        score  = entities.get(key)

        NamedEntity.annotate mention, type, score, (rstart..rend)
        
        mentions << mention
      end
    end

    mentions
  end
end



