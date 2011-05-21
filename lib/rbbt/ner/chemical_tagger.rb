require 'rbbt'
require 'rjb'
require 'rbbt/ner/annotations'
require 'rbbt/ner/NER'
require 'rbbt/util/log'

class ChemicalTagger < NER
  Rbbt.software.opt.ChemicalTagger.define_as_install Rbbt.share.install.software.ChemicalTagger.find

  Rjb::load(nil, jvmargs = ['-Xms128m','-Xmx2048m'])

  @@RbbtChemicalTagger = Rjb::import('RbbtChemicalTagger')

  def self.match(text,  type = nil, memm =  false)

    return [] if text.nil? or text.strip.empty?

    matches = @@RbbtChemicalTagger.match(text)

    matches.collect do |mention|
      offset = text.index mention
      NamedEntity.annotate mention, offset, "Chemical Mention", nil, nil
    end
  end

    def match(*args)
      ChemicalTagger.match(*args)
    end
  end
