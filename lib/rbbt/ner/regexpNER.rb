require 'rbbt/ner/annotations'
require 'rbbt/ner/NER'

class RegExpNER < NER
  def self.match_regexp(text, regexp, type = nil)
    matches = []
    start = 0
    while matchdata = text.match(regexp)
      pre   = matchdata.pre_match
      post  = matchdata.post_match
      match = matchdata[0]

      if matchdata.captures.any?
        capture = matchdata.captures.first
        more_pre, more_post = match.split(/#{capture}/)

        match = capture
        pre << more_pre || ""
        post = more_post || "" << post
      end

      if match and not match.empty?
        NamedEntity.annotate(match, start + pre.length, type)
        matches << match
      end

      start += pre.length + match.length
      text = post
    end

    matches
  end

  def self.match_regexp_list(text, regexp_list, type = nil)
    matches = []

    regexp_list.each do |regexp|
      chunks = Segment.split(text, matches)
      chunks.each do |chunk|
        new_matches = match_regexp(chunk, regexp, type)
        new_matches.each do |match| match.offset += chunk.offset; matches << match end
      end
    end

    matches
  end

  def self.match_regexp_hash(text, regexp_hash)
    matches = []

    regexp_hash.each do |type, regexp_list|
      regexp_list = [regexp_list] unless Array === regexp_list
      chunks = Segment.split(text, matches)
      chunks.each do |chunk|
        match_regexp_list(chunk, regexp_list, type).collect do |match| match.offset += chunk.offset; matches << match end
      end
    end

    matches
  end

  attr_accessor :regexps
  def initialize(regexps = {})
    @regexps = regexps
  end

  def match(text)
    matches = RegExpNER.match_regexp_hash(text, @regexps)
  end

end

