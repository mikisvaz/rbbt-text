require 'rbbt/ner/rnorm/cue_index'
require 'rbbt/ner/rnorm/tokens'
require 'rbbt/util/open'
require 'rbbt/tsv'
require 'rbbt/sources/entrez'
require 'rbbt/bow/bow.rb'

class Normalizer

  # Given a list of pairs of candidates along with their scores as
  # parameter +values+, and a minimum value for the scores. It returns
  # a list of pairs of the candidates that score the highest and that
  # score above the minimum. Otherwise it return an empty list.
  def self.get_best(values, min)
    return [] if values.empty?
    best = values.collect{|p| p[1] }.max
    return [] if best < min
    values.select{|p| p[1] == best}
  end

  # Compares the tokens and gives each candidate a score based on the
  # commonalities and differences amongst the tokens.
  def token_score(code, mention)
    return nil if @synonyms[code].nil?
    @synonyms[code].select{|name| name =~ /[a-zA-Z]/ }.collect{|name|
      value = case 
              when mention == name
                100
              when mention.downcase == name.downcase
                90
              when mention.downcase.gsub(/\s/,'') == name.downcase.gsub(/\s/,'')
                80
              else
                @tokens.evaluate(mention, name)
              end
      [value, name]
    }.sort_by{|value, name| value }.last
  end

  # Order candidates with the number of words in common between the text
  # in their Entrez Gene entry and the text passed as parameter. Because
  # candidate genes might be in some other format than Entrez Gene Ids,
  # the +to_entrez+ variable can hold the way to translate between them,
  # been a Proc or a Hash.
  def entrez_score(candidates, text, to_entrez = nil)
      code2entrez = {}
      candidates.each{|code, score|
        if to_entrez.is_a? Proc
          entrez = to_entrez.call(code)
        elsif to_entrez.is_a? Hash
          entrez = @to_entrez[code]
        else
          entrez = code
        end
        code2entrez[code] = entrez unless entrez.nil? 
      }

      # Get all at once, better performance
      genes = Entrez.get_gene(code2entrez.values)

      code2entrez_genes = code2entrez.collect{|key, value| [key, genes[value]]}

      code2entrez_genes.collect{|p|
        [p[0], Entrez.gene_text_similarity(p[1], text)]
      }
  end
  
  # Takes a list of candidate codes and selects the ones that have the
  # mention explicitly in their list of synonyms, and in the earliest
  # positions. This is based on the idea that synonym lists order their
  # synonyms by importance.
  def appearence_order(candidates, mention)
    positions = candidates.collect{|code, score, name|
      next unless @synonyms[code]
      pos = nil
      @synonyms[code].each_with_index{|list,i|
        next if pos
        pos = i if list.include? mention
      }
      pos 
    }

    return nil if positions.compact.empty?

    best = candidates.zip(positions).sort{|a,b| 
      case
      when (a[1].nil? and b[1].nil?)
        0
      when b[1].nil?
        1
      when a[1].nil?
        -1
      else
        a[1] <=> b[1]
      end
    }.first[1]
    candidates.zip(positions).select{|p| p[1] == best}
  end



  def initialize(lexicon, options = {})
    @synonyms = case lexicon
                when TSV
                  lexicon.unnamed = true
                  lexicon
                when Array
                  tsv = TSV.setup(lexicon, :fields => [], :type => :flat, :unnamed => true, :defaul_value => [])
                  tsv.add_field "Term" do |k,v|
                    k
                  end
                  tsv
                else
                  TSV.open(lexicon, :type => :flat, :unnamed => true)
                end

    @synonyms.process @synonyms.fields.first do |values, key|
      [key] + values
    end if options[:use_keys]

    @index = CueIndex.new
    @index.load(@synonyms, options[:max_candidates])

    @to_entrez = options[:to_entrez]
    @tokens = Tokenizer.new(options[:file])
  end

  def match(mention)
    @index.match(mention)
  end

  def select(candidates, mention, text = nil, options = {})
    options = Misc.add_defaults options, :threshold => 0, :max_candidates => 20, :max_entrez => 10, :keep_matches => false
    threshold, max_candidates, max_entrez, keep_matches = Misc.process_options options, :threshold, :max_candidates, :max_entrez, :keep_matches

    # Abort if too ambigous
    return [] if candidates.empty?
    return [] if candidates.length > max_candidates

    scores = candidates.zip(candidates.collect{|candidate| token_score(candidate, mention)}).collect{|v| v.flatten}
    scores.delete_if{|candidate, score, name| score.nil? or score <= threshold}

    best_codes = Normalizer::get_best(scores, threshold)

    # Abort if too ambigous
    return [] if best_codes.length > max_entrez

    if best_codes.length > 1 and text
      scores = entrez_score(best_codes.collect{|c| c.first}, text, @to_entrez)

      if keep_matches
        Normalizer::get_best(scores, 0)
      else
        Normalizer::get_best(scores, 0).collect{|p| p[0]}
      end
    else
      orders = appearence_order(best_codes, mention)
      if orders 
        if keep_matches
          orders.collect{|p| p[0]}
        else
          orders.collect{|p| p[0][0]}
        end
      else
        if keep_matches
          best_codes
        else
          best_codes.collect{|p| p[0]}
        end
      end
    end

  end

  def resolve(mention, text = nil, options = {})
    text, options = nil, text if options.empty? and Hash === text
    candidates = match(mention)
    select(candidates, mention, text, options)
  end

end

