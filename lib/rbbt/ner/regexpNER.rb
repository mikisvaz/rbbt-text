require 'rbbt/ner/NER'
require 'rbbt/util/simpleDSL'

class RegExpNER < NER
  include SimpleDSL

  def self.match_regexp(text, regexp, type = nil)
    matches = []
    start = 0
    while matchdata = text.match(regexp)
      pre   = matchdata.pre_match
      post  = matchdata.post_match

      if matchdata.captures.any?
        match = matchdata.captures.first
        offset, eend = matchdata.offset(1)
        NamedEntity.setup(match, :offset => start + offset, :entity_type => type)
        matches << match
        start += offset + match.length
        text = text[eend..-1] 
      else
        match = matchdata[0]
        NamedEntity.setup(match, :offset => pre.length + start, :entity_type => type)
        matches << match
        eend = match.length + pre.length
        text = text[eend..-1] 
        start += match.length + pre.length
      end
    end

    matches
  end

  def self.match_regexp_list(text, regexp_list, type = nil, split_on_matches = false)
    matches = []

    regexp_list.each do |regexp|
      chunks = split_on_matches ? Segment.split(text, matches) : Segment.split(text, [])
      chunks = Segment.split(text, [])
      chunks.each do |chunk|
        new_matches = match_regexp(chunk, regexp, type)
        new_matches.each do |match| match.offset += chunk.offset; matches << match end
      end
    end

    matches
  end

  def self.match_regexp_hash(text, regexp_hash, split_on_matches = false)
    matches = []

    regexp_hash.each do |type, regexp_list|
      regexp_list = [regexp_list] unless Array === regexp_list
      chunks = split_on_matches ? Segment.split(text, matches) : Segment.split(text, [])
      chunks.each do |chunk|
        chunk_offset = chunk.offset
        match_regexp_list(chunk, regexp_list, type, split_on_matches).each do |match| 
          match.offset = match.offset + chunk_offset; 
          matches << match 
        end
      end
    end

    matches
  end

  attr_accessor :regexps, :split_on_matches
  def initialize(regexps = {})
    @regexps = regexps.collect{|p| p }
  end

  def token_score(*args)
    1
  end

  def __define_regexp_hook(name, regexp, *args)
    @regexps << [name, regexp]
  end

  def define_regexp(*args, &block)
    load_config("__define_regexp_hook", *args, &block)
  end

  def add_regexp(list = {})
    @regexps.concat list.collect
  end

  def match(text)
    matches = RegExpNER.match_regexp_hash(text, @regexps, @split_on_matches)
    matches.collect do |m|
      NamedEntity.setup(m, :offset => m.offset, :type =>  m.type, :code => m)
    end
  end

end

