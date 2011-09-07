require 'rbbt'
require 'rbbt/util/misc'
require 'rbbt/util/simpleDSL'

class CueIndex
  include SimpleDSL

  class LexiconMissingError < StandardError; end

  def define(name, *args, &block)
    @rules << [name,block]
    nil
  end

  def initialize(file = nil, &block)
    @rules   = []

    file ||= Rbbt.share.rnorm.cue_default.produce if !file && !block

    load_config(:define, file, &block)
  end

  def config
    @config[:define]
  end


  def cues(word)
    @rules.collect{|rule|
      c = rule[1].call(word)
      c = [c] unless  c.is_a? Array 
      c
    }
  end

  def clean(max)
    @indexes.each{|index|
      remove = []
      index.each{|key,values|
        remove << key if values.length > max
      }
      remove.each{|key|
        index.delete(key)
      }
    }
  end
  
  def load(file, max_candidates = 50)
    @indexes = Array.new(@rules.size){Hash.new}
    data = TSV.open(file, :flat)
    data.each{|code, values|
      values.each{|value|
        cues(value).each_with_index{|cue_list,i|
          cue_list.each{|cue|
            @indexes[i][cue] ||= []
            @indexes[i][cue]  << code unless @indexes[i][cue].include? code
          }
        }
      }
    }
    clean(max_candidates) if max_candidates
    nil
  end

  def match(name)
    raise LexiconMissingError, "Load Lexicon before matching" unless @indexes

    cues = cues(name)
    @indexes.each_with_index{|index,i|
      best = []
      cues[i].each{|cue|
        best << index[cue] if index[cue]
      }
      return best.flatten if best.any?
    }

    return []
  end

end
