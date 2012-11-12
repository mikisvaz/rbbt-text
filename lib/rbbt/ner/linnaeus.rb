require 'rjb'
require 'rbbt'
require 'rbbt/ner/segment/named_entity'
module Linnaeus

  Rbbt.claim Rbbt.software.opt.Linnaeus, :install, Rbbt.share.install.software.Linnaeus.find



  ARGS = ["--properties", Rbbt.software.opt.Linnaeus["species-proxy/properties.conf"].find]

  def self.init
    begin
      Rjb::load(nil, jvmargs = ['-Xms2G','-Xmx4G']) unless Rjb.loaded?
      @@ArgParser    = Rjb::import('martin.common.ArgParser')
      @@Args         = @@ArgParser.new(ARGS)
      @@Loggers      = Rjb::import('martin.common.Loggers')
      @@Logger       = @@Loggers.getDefaultLogger(@@Args)
      @@EntityTagger = Rjb::import('uk.ac.man.entitytagger.EntityTagger')
      @@Matcher      = @@EntityTagger.getMatcher(@@Args, @@Logger)
    rescue
      if $!.message =~ /heap space/i
        Log.warn "Heap Space seems too low. Make sure Linnaeus is loaded before other Java wrappers so that it has the chance to init the Java Bridge with sufficient heap space"
      end
      raise $!
    end
  end

  def self.match(text)

    init unless defined? @@Matcher

    @@Matcher.match(text).toArray().collect do |mention|
      NamedEntity.setup(mention.text(), mention.start(), "Organism", mention.ids(), mention.probabilities())
    end
  end
end

