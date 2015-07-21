require 'rbbt/ner/rnorm'
require 'rbbt/ner/regexpNER'

class Finder
  
  if defined? Entity
    module Match
      extend Entity

      self.annotation :format
      self.annotation :namespace
      self.annotation :score
    end
  end

  class Instance
    attr_accessor :namespace, :format, :normalizer
    def initialize(path, open_options = {})
      case path
      when TSV 
        @namespace = path.namespace 
        @format = path.key_field
        @normalizer = Normalizer.new(path)
      when Hash
        @namespace = open_options[:namespace]
        @format = nil
        @normalizer = RegExpNER.new(path)
      else
        open_options = Misc.add_defaults open_options, :type => :flat
        tsv = TSV.open(path, open_options)
        @namespace = tsv.namespace 
        @format = tsv.key_field
        @normalizer = Normalizer.new(tsv)
      end
    end

    def find(name)
      candidates = @normalizer.match(name)
      if defined? Finder::Match
        candidates.collect{|c|
          Finder::Match.setup(c.dup, @format, @namespace, @normalizer.token_score(c, name))
        }
      else
        candidates
      end
    end
  end

  attr_accessor :instances
  def initialize(path = nil, open_options = {})
    @instances ||= []
    @instances << Finder::Instance.new(path, open_options) unless path.nil?
  end

  def add_instance(path, open_options = {})
    @instances << Finder::Instance.new(path, open_options)
  end

  def find(name)
    @instances.inject([]) do |acc,instance|
      acc += instance.find(name)
    end
  end
end
