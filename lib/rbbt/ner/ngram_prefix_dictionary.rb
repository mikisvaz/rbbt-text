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
  STOP_LETTER_CHAR_VALUES = STOP_LETTERS.collect{|l| l[0]}
  class << self
    inline do |builder|

      builder.c_raw <<-EOC
int is_stop_letter(char letter)
{

  if( letter == ' ' || #{STOP_LETTERS.collect{|l| "letter == '#{l}' "} * "||"} ){ return 1;}

  return 0;
}
      EOC

      builder.c <<-EOC
VALUE fast_start_with(VALUE str, VALUE cmp, int offset)
{
  int length_cmp = RSTRING_LEN(cmp);
  int length_str = RSTRING_LEN(str);

  if (memcmp(RSTRING_PTR(str)+ offset, RSTRING_PTR(cmp), length_cmp) == 0){
    if (length_cmp - offset == length_str || is_stop_letter(RSTRING_PTR(str)[offset + length_cmp]))
      return Qtrue;
    else
      return Qfalse;
  }

  return Qfalse;
}
      EOC
    end
  end

  def self.process_stream(stream)
    index = {}
    while line = stream.gets
      names = line.split(/\t|\|/).select{|n| not n.empty?}.compact
      code = names.shift
      
      names.each do |name|
        ngram = name[0..2].strip
        index[ngram] ||= []
        index[ngram] << [name, code]
      end
    end
    index
 
  end

  def self.process_hash(hash)
    index = {}
    hash.monitor = true if hash.respond_to? :monitor
    hash.unnamed = true if hash.respond_to? :unnamed
    method = hash.respond_to?(:through)? :through : :each
    hash.send(method) do |code, names|
      names.each do |name|
        ngram = name[0..2].strip
        index[ngram] ||= []
        index[ngram] << [name, code]
      end
    end
    index
  end

  def self.match(index, text)
    matches = []

    text_offset = 0
    text_length = text.length
    while (not text_offset.nil?) and text_offset < text_length
      text_offset += 1 if STOP_LETTER_CHAR_VALUES.include? text[text_offset]
      ngram =  text[text_offset..text_offset + 2].strip

      found = nil
      if index.include? ngram

        diff = text_length - text_offset
        # Match with entries
        index[ngram].each do |name, code|
          if name.length < diff
            #if piece.start_with? name and 
            #  (text_offset + name.length == text_length or piece[name.length] == " "[0])

            if fast_start_with(text, name, text_offset)
              found = [name, code, text_offset]
              break
            end
          end
        end
      end

      if found.nil?
        text_offset = text.index(" ", text_offset)
        text_offset += 1 unless text_offset.nil?
      else
        matches << found
        text_offset += found.first.length
      end
    end

    matches
  end

  attr_accessor :index, :type
  def initialize(file, type = nil)
    @type = type
    case
    when (TSV === file or Hash === file)
      Log.debug("Ngram Prefix Dictionary. Loading of lexicon hash started.")
      @index = NGramPrefixDictionary.process_hash(file)
    when Path === file
      Log.debug("Ngram Prefix Dictionary. Loading of lexicon file started: #{ file }.")
      @index = NGramPrefixDictionary.process_stream(file.open)
    when Misc.is_filename?(file)
      Log.debug("Ngram Prefix Dictionary. Loading of lexicon file started: #{ file }.")
      @index = NGramPrefixDictionary.process_stream(Open.open(file))
    when StreamIO === file
      Log.debug("Ngram Prefix Dictionary. Loading of lexicon stream started.")
      @index = NGramPrefixDictionary.process_stream(file)
    else
      raise "Format of lexicon not understood: #{file.inspect}"
    end

    Log.debug("Ngram Prefix Dictionary. Loading done.")
  end

  def match(text)
    NGramPrefixDictionary.match(index, text).collect{|name, code, offset|
      NamedEntity.setup(name, offset, type, code)
    }
  end
end

if __FILE__ == $0
  require 'rbbt/sources/jochem'
  require 'rbbt/sources/pubmed'

  texts = []
  index = {}

  texts = PubMed.get_article(PubMed.query("GB-1a", 100)).collect do |pmid, article|
    article.text
  end

  texts *= 150/texts.length

  tsv = Rbbt.share.databases.JoChem.lexicon.tsv :flat, :persistence => false, :grep => "GB"
  #tsv = Rbbt.share.databases.JoChem.lexicon.tsv :flat, :persistence => true

  tsv.unnamed = true
  ner = NGramPrefixDictionary.new(tsv)

  Misc.benchmark do
    texts.each do |text|
      ner.match(text)
    end
  end


end
