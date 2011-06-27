require 'rbbt-util'
require 'rbbt/util/tsv'
require 'rbbt/ner/annotations'
require 'rbbt/ner/annotations/token'
require 'rbbt/ner/NER'

class TokenTrieNER < NER
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

  module EnumeratedArray
    attr_accessor :pos
    def self.extended(array)
      array.pos = 0
    end

    def last?
      @pos == length - 1
    end

    def advance
      @pos += 1
    end

    def back
      @pos -= 1
    end

    def next
      e = self[@pos]
      advance
      e 
    end

    def peek
      self[@pos]
    end

    def left?
      @pos < length
    end

  end


  class Code
    attr_accessor :code, :type
    def initialize(code, type = nil)
      @code = code
      @type = type
    end

    def to_s
      [type, code] * ":"
    end
  end

  def self.index_for_tokens(tokens, code, type = nil, slack = nil)
    if tokens.empty?
      {:END => [Code.new(code, type)]}
    else
      head = tokens.shift
      if (slack.nil? or not slack.call(head))
        {head => index_for_tokens(tokens, code, type, slack)}
      else
        res = {head => index_for_tokens(tokens.dup, code, type, slack)}.merge(index_for_tokens(tokens, code, type, slack))
      end
    end
  end

  def self.merge(index1, index2)
    index2.each do |key, new_index2|
      case
      when key == :END
        index1[:END] ||= []
        index1[:END] += new_index2.reject{|new| index1[:END].collect{|e| e.to_s }.include? new.to_s }
        index1[:END].uniq!
      when index1.include?(key)
        merge(index1[key], new_index2)
      else
        index1[key] = new_index2
      end
    end
  end

  def self.process(hash, type = nil, slack = nil)
    index = {}

    hash.through do |code, names|
      names = Array === names ? names : [names]
      names.flatten! if Array === names.first and not Token === names.first.first
      names.each do |name|
        next if name.empty? or (String === name and name.length < 2)
        tokens = Array === name ? name : tokenize(name) 

        merge(index, index_for_tokens(tokens, code, type, slack)) unless tokens.empty?
      end
    end
    index
  end

  #{{{ Matching
  
  def self.follow(index, head)
    res = nil

    if index.include? head
      return index[head]
    end

    return nil unless index.include? :PROCS

    index[:PROCS].each do |key,value|
      return value if key.call(head)
    end

    nil
  end
  
  def self.find_fail(index, tokens, head, longest_match, slack, first)
    if Proc === slack and not first and not head.nil? and tokens.left? and slack.call(head) 
      matches = find(index, tokens, longest_match, slack, false) # Recursion
      if not matches.nil?
        matches.last.unshift head
        return matches
      end
    end

    tokens.back
    return nil
  end
 
  def self.find(index, tokens, longest_match = true, slack = nil, first = true)
    head = tokens.next
    
    next_index = follow(index, head)


    return find_fail(index, tokens, head, longest_match, slack, first) if next_index.nil?

    if not tokens.left?
      if next_index.include? :END
        return [next_index[:END], [head]]
      else
        return find_fail(index, tokens, head, longest_match, slack, first)
      end
    else

      return [next_index[:END], [head]] if next_index.include?(:END) and not longest_match

      matches = find(next_index, tokens, longest_match, slack, false) # Recursion

      if not matches.nil?
        matches.last.unshift head
        return matches
      end
      
      return [next_index[:END], [head]] if next_index.include?(:END)

      return find_fail(index, tokens, head, longest_match, slack, first)
    end
  end

  def self.make_match(match_tokens, type, codes)
    match = ""
    match_offset = match_tokens.first.offset
    match_tokens.each{|t| 
      match << " " * (t.offset - (match_offset + match.length)) if t.offset > (match_offset + match.length)
      match << (t.respond_to?(:original) ? t.original : t)
    }

    NamedEntity.annotate(match, match_tokens.first.offset, type, codes)
  end

  attr_accessor :index, :longest_match, :type, :slack
  def initialize(file, type = nil, slack = nil, options = {})
    options = Misc.add_defaults options, :longest_match => true
    @longest_match = options.delete :longest_match

    file = [file] unless Array === file
    @index = {}
    file.each do |f| 
      merge(f, type)
    end
  end

  def merge(new, type = nil)
    case
    when TokenTrieNER === new
      TokenTrieNER.merge(@index, new.index)
    when Hash === new
      TokenTrieNER.merge(@index, new)
    when TSV === new
      old_unnamed = new.unnamed
      old_monitor = new.monitor
      new.unnamed = true
      new.monitor = true
      TokenTrieNER.merge(@index, TokenTrieNER.process(new, type, slack))
      new.unnamed = old_unnamed
      new.monitor = old_monitor
    when String === new
      new = TSV.new(new, :flat)
      new.unnamed = true
      new.monitor = {:step => 1000, :desc => "Processing TSV into TokenTrieNER"}
      TokenTrieNER.merge(@index, TokenTrieNER.process(new, type, slack))
    end
  end

  def match(text)
    tokens = Array === text ? text : TokenTrieNER.tokenize(text)

    tokens.extend EnumeratedArray
    tokens.pos = 0

    matches = []
    while tokens.left?
      new_matches = TokenTrieNER.find(@index, tokens, longest_match, slack) 

      if new_matches
        codes, match_tokens = new_matches
        matches << TokenTrieNER.make_match(match_tokens, codes.collect{|c| c.type}, codes.collect{|c| c.code})
      else
        tokens.advance
      end
    end

    matches
  end

end

