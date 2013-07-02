require 'rbbt'
require 'rjb'
require 'rbbt/ner/segment'
require 'rbbt/ner/NER'
require 'rbbt/util/log'

class ChemicalTagger < NER
  Rbbt.claim Rbbt.software.opt.ChemicalTagger, :install, Rbbt.share.install.software.ChemicalTagger.find

  def self.init
    ENV["CLASSPATH"] = ENV["CLASSPATH"].split(":").reverse * ":"
    Rjb::load(nil, jvmargs = ['-Xms1G','-Xmx2G']) unless Rjb.loaded?
    @@RbbtChemicalTagger ||= Rjb::import('RbbtChemicalTagger')
  end

  def self.match(text,  type = nil, memm =  false)
    self.init

    return [] if text.nil? or text.strip.empty?

    begin
      matches = @@RbbtChemicalTagger.match(text)
    rescue
      Log.debug "ChemicalTagger Error: #{$!.message}"
      ddd $!.backtrace
      return []
    end

    matches.collect do |mention|
      offset = text.index mention
      NamedEntity.setup mention, offset, "Chemical Mention", nil, nil
    end
  end

  def match(*args)
    ChemicalTagger.match(*args)
  end
end
