require 'rjb'
require 'rbbt'
require 'rbbt/segment/named_entity'

module Linnaeus

  Rbbt.claim Rbbt.software.opt.Linnaeus, :install, Rbbt.share.install.software.Linnaeus.find

  ARGS = ["--properties", Rbbt.software.opt.Linnaeus.produce["species-proxy/properties.conf"].find]


  Rjb::load(nil, jvmargs = ['-Xms2G','-Xmx2G']) unless Rjb.loaded?
  def self.init
    begin
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
      best_id, best_prob = mention.ids().zip(mention.probabilities()).sort_by{|i,p| p.to_f }.last
      NamedEntity.setup(mention.text(), :offset => mention.start(), :entity_type => "Organism", :code => best_id, :score => best_prob)
    end
  end
end

