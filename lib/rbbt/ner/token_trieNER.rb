require 'rbbt-util'
require 'rbbt/util/tsv'
require 'rbbt/ner/annotations'
require 'rbbt/ner/NER'

class TokenTrieNER
  def self.clean(token)
    if token.length > 3
      token.downcase
    else
      token
    end
  end

  def self.prepare_token(token, start)
    Token.annotate(clean(token), start, token)
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

  #{{{ Process dictionary
   
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

  def self.make_match(match_tokens, type, codes)
    match = ""
    match_offset = match_tokens.first.offset
    match_tokens.each{|t| 
      match << " " * (t.offset - (match_offset + match.length)) if t.offset > (match_offset + match.length)
      match << t.original
    }

    NamedEntity.annotate(match, match_tokens.first.offset, type, codes)
  end

  attr_accessor :index, :longest_match, :type
  def initialize(file, type = nil, options = {})
    options = Misc.add_defaults options, :flatten => true, :longest_match => true
    @longest_match = options.delete :longest_match

    file = [file] unless Array === file
    @index = {}
    file.each do |f| TokenTrieNER.merge(@index, TokenTrieNER.process(TSV.new(f, options))) end
  end

  def merge(new)
    case
    when TokenTrieNER === new
      TokenTrieNER.merge(@index, new.index)
    when Hash === new
      TokenTrieNER.merge(@index, new)
    when String === new
      TokenTrieNER.merge(@index, TokenTrieNER.process(TSV.new(new, :flatten => true)))
    end
  end

  def match(text)
    tokens = TokenTrieNER.tokenize text

    matches = []
    while tokens.any?
      new_matches = TokenTrieNER.find(@index, tokens, longest_match) 

      if new_matches
        codes, match_tokens = new_matches
        matches << TokenTrieNER.make_match(match_tokens, type, codes)
      else
        tokens.shift
      end
    end

    matches
  end

end

