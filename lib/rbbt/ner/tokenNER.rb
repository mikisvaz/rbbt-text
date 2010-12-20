require 'rbbt-util'
require 'rbbt/util/tsv'

class TokenNER

  module AnnotatedToken 
    attr_accessor :original, :range
  end

  def self.clean(token)
    token.downcase
  end

  def self.prepare_token(token, start)
    clean_token = clean token
    clean_token.extend AnnotatedToken
    clean_token.original = token
    clean_token.range = (start..start + token.length)
    clean_token
  end

  def self.tokenize(text, split_at = /\s|(\(|\)|[-."':,])/)

    tokens = []
    start = 0
    while matchdata = text.match(split_at)
      tokens << prepare_token(matchdata.pre_match, matchdata.begin(0)) unless matchdata.pre_match.empty?
      tokens << prepare_token(matchdata.captures.first, matchdata.begin(1)) if matchdata.captures.any? and not matchdata.captures.first.empty?
      start = matchdata.end(0)
      text = matchdata.post_match
    end
    tokens << prepare_token(text, start)

    tokens
  end

  def self.index_for_tokens(tokens, code)
    if tokens.empty?
      {:END => [code]}
    else
      {tokens.shift => index_for_tokens(tokens, code)}
    end
  end
  
  def self.merge(index1, index2)
    index2.each do |key, new_index2|
      case
      when key == :END
        index1[:END] ||= []
        index1[:END] += new_index2
        index1[:END].uniq!
      when index1.include?(key)
        merge(index1[key], new_index2)
      else
        index1[key] = new_index2
      end
    end
  end

  def self.process(hash)
    index = {}
    hash.each do |code, names|
      names.each do |name|
        tokens = tokenize name

        merge(index, index_for_tokens(tokens, code))
      end
    end
    index
  end

  def self.find(index, tokens, longest_match = true)
    return nil unless index.include? tokens.first

    head = tokens.shift
    next_index = index[head]

    if tokens.empty?
      if next_index.include? :END
        return [next_index[:END], [head]]
      else
        tokens.unshift head
        return nil
      end
    else

      return [next_index[:END], [head]] if next_index.include?(:END) and not longest_match

      matches = find(next_index, tokens)
      if not matches.nil?
        matches.last.unshift head
        return matches
      end
      
      return [next_index[:END], [head]] if next_index.include?(:END)

      tokens.unshift head
      return nil
    end
  end

  attr_accessor :index, :longest_match
  def initialize(file, options = {})
    options = Misc.add_defaults options, :flatten => true, :longest_match => true
    @longest_match = options.delete :longest_match

    file = [file] unless Array === file
    @index = {}
    file.each do |f| TokenNER.merge(@index, TokenNER.process(TSV.new(f, options))) end
  end

  def merge(new)
    case
    when TokenNER === new
      TokenNER.merge(@index, new.index)
    when Hash === new
      TokenNER.merge(@index, new)
    when String === new
      TokenNER.merge(@index, TokenNER.process(TSV.new(new, :flatten => true)))
    end
  end

  def extract(text)
    tokens = TokenNER.tokenize text

    matches = {}
    while tokens.any?
      new_matches = TokenNER.find(@index, tokens, longest_match) 
      if new_matches
        codes, match_tokens = new_matches
        match = match_tokens.collect{|t| t.original} * " "
        match.extend NamedEntity
        match.range = (match_tokens.first.range.begin..match_tokens.last.range.end)
        codes.each do |code|
            matches[code] ||= []
            matches[code] << match
        end
      else
        tokens.shift
      end
    end

    matches
  end

end
