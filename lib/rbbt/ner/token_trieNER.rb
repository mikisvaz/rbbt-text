require 'rbbt'
require 'rbbt/tsv'
require 'rbbt/segment'
require 'rbbt/ner/NER'
require 'rbbt/segment/token'

class TokenTrieNER < NER
  def self.clean(token, stem = false)
    if token.length > 3
      upcase = token !~ /[a-z]/
      token = token.downcase.sub(/-/,'')

      if stem && ! upcase
        require 'stemmer'
        if stem == :double
          token = token.stem.stem
        else
          token = token.stem
        end
      end

      token
    else
      token
    end
  end

  def self.prepare_token(token, start, extend_to_token = true, no_clean = false, stem = false)
    if no_clean
      if extend_to_token
        Token.setup(token, :offset => start, :original => token)
      else
        token
      end
    else
      if extend_to_token
        Token.setup(clean(token, stem), :offset => start, :original => token)
      else
        clean(token, stem)
      end
    end
  end

  def self.tokenize(text, extend_to_token = true, split_at = nil, no_clean = false, stem = false, start = 0)
    split_at = /\s|(\(|\)|[-."':,])/ if split_at.nil?

    tokens = []
    while matchdata = text.match(split_at)
      tokens << prepare_token(matchdata.pre_match, start, extend_to_token, no_clean, stem) unless matchdata.pre_match.empty?
      tokens << prepare_token(matchdata.captures.first, start + matchdata.begin(1), extend_to_token, no_clean, stem) if matchdata.captures.any? and not matchdata.captures.first.empty?
      start += matchdata.end(0)
      text = matchdata.post_match
    end
     
    tokens << prepare_token(text, start, extend_to_token, no_clean, stem) unless text.empty?

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
    if not tokens.left?
      {:END => [Code.new(code, type)]}
    else
      head = tokens.next
      if (slack.nil? or not slack.call(head))
        res = {head => index_for_tokens(tokens, code, type, slack)}
      else
        res = {head => index_for_tokens(tokens, code, type, slack)}.merge(index_for_tokens(tokens, code, type, slack))
      end
      tokens.back
      res
    end
  end

  def self.merge(index1, index2)
    index1.write if index1.respond_to? :write and not index1.write?
    index2.each do |key, new_index2|
      case
      when key == :END
        end1 = index1[:END] || []
        end1 += new_index2.reject{|new| end1.collect{|e| e.to_s }.include? new.to_s }
        end1.uniq!
        index1[:END] = end1
      when index1.include?(key)
        new = merge(index1[key], new_index2)
        index1[key] = new
      else
        index1[key] = new_index2
      end
    end
    index1.read if index1.respond_to? :read

    index1
  end

  def self.process(index, hash, type = nil, slack = nil, split_at = nil, no_clean = false, stem = false)

    chunk_size = hash.size / 100
    items_in_chunk = 0
    tmp_index = {}
    hash.send(hash.respond_to?(:through)? :through : :each) do |code, names|
      names = Array === names ? names : [names]
      names.flatten! if Array === names.first and not Segment === names.first.first

      if names.empty?
        names.unshift code unless TSV === hash and not (hash.fields.nil? or hash.fields.empty?)
      end

      names.each do |name|
        next if name.empty? or (String === name and name.length < 2)

        tokens = Array === name ? name : tokenize(name, false, split_at, no_clean, stem) 
        tokens.extend EnumeratedArray

        token_index = index_for_tokens(tokens, code, type, slack)

        tmp_index = merge(tmp_index, token_index) unless tokens.empty?

        items_in_chunk += 1

        if items_in_chunk > chunk_size
          index = merge(index, tmp_index)
          tmp_index = {}
          items_in_chunk = 0
        end
      end
    end
    index = merge(index, tmp_index)

    index
  end

  #{{{ Matching
  
  def self.follow(index, head)
    res = nil

    if index.include? head
      return index[head]
    end

    return nil unless (not TokyoCabinet::HDB === index ) and index.include? :PROCS

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
      match << ((t.respond_to?(:original) and not t.original.nil?) ? t.original : t)
    }

    NamedEntity.setup(match, :offset => match_tokens.first.offset, :entity_type => type, :code => codes)
  end

  attr_accessor :index, :longest_match, :type, :slack, :split_at, :no_clean, :stem
  def initialize(type = nil, file = nil, options = {})
    options = Misc.add_defaults options, :longest_match => true, :no_clean => false, :slack => nil, :split_at => nil,
      :persist => false
    @slack = slack
    @longest_match = options.delete :longest_match
    @split_at = options.delete :split_at
    @no_clean = options.delete :no_clean
    @stem = options.delete :stem

    file = [] if file.nil?
    file = [file] unless Array === file
    persist_options = Misc.pull_keys options, :persist
    @index = Persist.persist_tsv(file, options, persist_options) do |data|
      data.serializer = :marshal if data.respond_to? :serializer and data.serializer == :type

      @index = data
      file.each do |f| 
        merge(f, type)
      end

      @index
    end
  end

  def merge(new, type = nil)
    case
    when TokenTrieNER === new
      Log.debug "TokenTrieNER merging other TokenTrieNER"
      TokenTrieNER.merge(@index, new.index)
    when TSV === new
      Log.debug "TokenTrieNER merging TSV"
      new.with_unnamed do
        new.with_monitor({:step => 1000, :desc => "Processing TSV into TokenTrieNER"}) do
          TokenTrieNER.process(@index, new, type, slack, split_at, no_clean, stem)
        end
      end
    when Hash === new
      Log.debug "TokenTrieNER merging Hash"
      TokenTrieNER.merge(@index, new)
    when String === new
      Log.debug "TokenTrieNER merging file: #{ new }"
      new = TSV.open(new, :flat)
      new.with_unnamed do
        new.with_monitor({:step => 1000, :desc => "Processing TSV into TokenTrieNER"}) do
          TokenTrieNER.process(@index, new, type, slack, split_at, no_clean, stem)
        end
      end
    end
  end

  def match(text)
    tokens = Array === text ? text : TokenTrieNER.tokenize(text, true, split_at, no_clean, stem)

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
