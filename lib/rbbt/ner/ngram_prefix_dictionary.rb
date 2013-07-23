require 'rbbt'
require 'rbbt/util/misc'
require 'rbbt/tsv'
require 'rbbt/ner/segment'
require 'rbbt/ner/segment/token'
require 'rbbt/ner/NER'
require 'inline'


# This code was adapted from Ashish Tendulkar (ASK MARTIN)
class NGramPrefixDictionary < NER
  STOP_LETTERS = %w(\' " ( ) { } [ ] - ? ! < ; : > . ,)
  STOP_LETTER_CHAR_VALUES = STOP_LETTERS.collect{|l| l[0]} + ["\n", "\r", " "].collect{|l| l[0]}
  LETTER_REGEXP = Regexp.compile(/[#{Regexp.quote((STOP_LETTERS + ["\n", "\r", " "]) * "")}]/)

  inline do |builder|

    builder.c_raw_singleton <<-EOC
int is_stop_letter(char letter)
{

  if( letter == ' ' || letter == '\\n' || letter == '\\r' || #{STOP_LETTERS.collect{|l| "letter == '#{l}' "} * "||"} ){ return 1;}

  return 0;
}
    EOC

    builder.c_singleton <<-EOC
VALUE fast_start_with(VALUE str, VALUE cmp, int offset)
{
  int length_cmp = RSTRING_LEN(cmp);
  int length_str = RSTRING_LEN(str);

  if (memcmp(RSTRING_PTR(str) + offset, RSTRING_PTR(cmp), length_cmp) == 0){
    if (length_cmp - offset == length_str || is_stop_letter(RSTRING_PTR(str)[offset + length_cmp]))
      return Qtrue;
    else
      return Qfalse;
  }

  return Qfalse;
}
    EOC
  end

  def self.process_stream(stream, case_insensitive = false)
    index = {}

    while line = stream.gets
      names = line.split(/\t|\|/).select{|n| not n.empty?}.compact
      code = names.shift
      
      names.each do |name|
        name = name.downcase if case_insensitive
        ngram = name[0..2].strip
        index[ngram] ||= []
        index[ngram] << [name, code]
      end
    end

    index
  end

  def self.process_hash(hash, case_insensitive = false)
    index = {}

    hash.monitor = true if hash.respond_to? :monitor
    hash.unnamed = true if hash.respond_to? :unnamed
    method = hash.respond_to?(:through)? :through : :each

    hash.send(method) do |code, names|
      names.each do |name|
        name = name.downcase if case_insensitive
        ngram = name[0..2].strip
        index[ngram] ||= []
        index[ngram] << [name, code]
      end
    end

    index
  end


  def self.match(index, text)
    return [] if text.nil? or text.empty?

    matches = []

    text_offset = 0
    text_chars = text.chars.to_a
    text_length = text.length
    while (not text_offset.nil?) and text_offset < text_length
      if STOP_LETTER_CHAR_VALUES.include? text[text_offset]
        text_offset += 1 
        next
      end
      ngram =  text.slice(text_offset, 3).strip
      text_byte_offset = text_offset == 0 ? 0 : text[0..text_offset-1].bytesize

      found = nil
      if index.include? ngram
        diff = text_length - text_offset
        # Match with entries
        index[ngram].each do |name, code|
          if name.length <= diff
            if fast_start_with(text, name, text_byte_offset)
              found = [name.dup, code, text_offset]
              break
            end
          end
        end
      end

      if found.nil?
        text_offset = text.index(LETTER_REGEXP, text_offset)
        text_offset += 1 unless text_offset.nil?
      else
        matches << found
        text_offset += found.first.length
      end
    end

    matches
  end


  attr_accessor :index, :type, :case_insensitive
  def initialize(file, type = nil, case_insensitive = false)
    @type = type
    @case_insensitive = case_insensitive
    case
    when (TSV === file or Hash === file)
      Log.debug("Ngram Prefix Dictionary. Loading of lexicon hash started.")
      @index = NGramPrefixDictionary.process_hash(file, case_insensitive)
    when Path === file
      Log.debug("Ngram Prefix Dictionary. Loading of lexicon file started: #{ file }.")
      @index = NGramPrefixDictionary.process_stream(file.open, case_insensitive)
    when Misc.is_filename?(file)
      Log.debug("Ngram Prefix Dictionary. Loading of lexicon file started: #{ file }.")
      @index = NGramPrefixDictionary.process_stream(Open.open(file))
    when StreamIO === file
      Log.debug("Ngram Prefix Dictionary. Loading of lexicon stream started.")
      @index = NGramPrefixDictionary.process_stream(file, case_insensitive)
    else
      raise "Format of lexicon not understood: #{file.inspect}"
    end

    Log.debug("Ngram Prefix Dictionary. Loading done.")
  end

  def match(text)
    matches = NGramPrefixDictionary.match(index, (case_insensitive ? text.downcase : text)).collect{|name, code, offset|
      NamedEntity.setup(name, offset, type, code)
    }

    if case_insensitive
      matches.each{|m| m.replace(text[m.range])}
      matches
    else
      matches
    end
  end
end
