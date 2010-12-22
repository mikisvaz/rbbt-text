require 'rbbt-util'
require 'rbbt/util/tsv'
require 'rbbt/util/simpleDSL'
require 'rbbt/ner/named_entity'

class TokenNER
  include SimpleDSL

  module AnnotatedToken 
    attr_accessor :original, :range
  end

  def self.clean(token)
    if token.length > 3
      token.downcase
    else
      token
    end
  end

  def self.prepare_token(token, start)
    clean_token = clean token
    clean_token.extend AnnotatedToken
    clean_token.original = token
    clean_token.range = (start..(start + token.length - 1))
    clean_token
  end

  def self.tokenize(text, split_at = /\s|(\(|\)|[-."':,])/, start = 0)

    tokens = []
    while matchdata = text.match(split_at)
      tokens << prepare_token(matchdata.pre_match, start) unless matchdata.pre_match.empty?
      tokens << prepare_token(matchdata.captures.first, start + matchdata.begin(1)) if matchdata.captures.any? and not matchdata.captures.first.empty?
      start += matchdata.end(0)
      text = matchdata.post_match
    end
    tokens << prepare_token(text, start) unless text.empty?

    tokens
  end

  def self.match_regexp(text, regexp, start = 0)
    chunks = []
    matches = []
    while matchdata = text.match(regexp)
      pre   = matchdata.pre_match
      post  = matchdata.post_match
      match = matchdata[0]

      if matchdata.captures.any?
        more_pre, more_post = match.split(/#{matchdata.captures.first}/)
        match = matchdata.captures.first
        pre << more_pre
        post = more_post << post
      end

      chunks << [pre, start]

      matches << prepare_token(match, start + pre.length) unless match.empty?
      start += pre.length + match.length
      text = matchdata.post_match
    end
    chunks << [text, start]

    [matches, chunks]
  end

  def self.match_regexps(text, regexps)
    start = 0
    chunks = [[text, 0]]

    matches = []
    regexps.each do |regexp, type|
      
      new_regexp_chunks = []
      chunks.each do |chunk, start|
        new_matches, new_chunk_chunks = match_regexp(chunk, regexp, start)

        new_matches.each do |new_match|
          new_match.extend NamedEntity
          new_match.type = type
          matches << new_match
        end

        new_regexp_chunks.concat new_chunk_chunks
      end
      chunks = new_regexp_chunks

    end
    [matches, chunks]
  end

  def self.tokenize_with_regexps(text, regexps = [], split_at = /\s|(\(|\)|[-."':,])/)
    matches, chunks = match_regexps(text, regexps)

    tokens = matches
    chunks.each do |chunk, start|
      tokens.concat tokenize(chunk, split_at, start)
    end

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
        next if name.empty? or name.length < 2
        tokens = tokenize name

        merge(index, index_for_tokens(tokens, code)) unless tokens.empty?
      end
    end
    index
  end

  attr_accessor :index, :longest_match
  def initialize(file, options = {})
    options = Misc.add_defaults options, :flatten => true, :longest_match => true
    @longest_match = options.delete :longest_match

    @regexps = options[:regexps] || []

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

  def __define_regexp_hook(name, regexp, *args)
    @regexps << [regexp, name.to_s]
  end

  def define_regexp(*args, &block)
    load_config("__define_regexp_hook", *args, &block)
  end

  def add_regexp(list = {})
    @regexps.concat list.collect
  end

  #{{{ Matching
  
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

  def extract(text)
    tokens = TokenNER.tokenize_with_regexps text, @regexps

    matches = {}
    while tokens.any?
      while NamedEntity === tokens.first
        matches[tokens.first.type] ||= []
        matches[tokens.first.type] << tokens.first
        tokens.shift
      end

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
