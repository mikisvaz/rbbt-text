require 'rbbt/ner/annotations/named_entity'
require 'rbbt/ner/annotations/annotated'
require 'rbbt/ner/annotations/transformed'
require 'rbbt/ner/regexpNER'
require 'rbbt/ner/token_trieNER'
require 'rbbt/nlp/nlp'
require 'stemmer'

class PatternRelExt
  attr_accessor :token_trie

  def new_token_trie
    @token_trie = TokenTrieNER.new({})
  end

  def token_trie
    @token_trie || new_token_trie
  end


  def slack(slack)
    @token_trie.slack = slack
  end
  
  def simple_pattern(sentence, patterns)
    patterns = Array === patterns ? patterns : [patterns]
    Transformed.with_transform(sentence, sentence.annotations, Proc.new{|s| s.type.to_s.upcase}) do |sentence|
      token_trie.merge(TSV.new({:pattern => [patterns]}))
      token_trie.entities(sentence)
    end
  end

  def self.transform_key(key)
    case
    when key =~ /(.*)\[entity:(.*)\]/
      chunk_type, chunk_value = $1, $2
      Proc.new{|chunk| (chunk_type == "all" or chunk.type == chunk_type) and chunk.annotations.select{|a| a.type == chunk_value}.any?}
    when key =~ /(.*)\[code:(.*)\]/
      chunk_type, chunk_value = $1, $2
      Proc.new{|chunk| (chunk_type == "all" or chunk.type == chunk_type) and chunk.annotations.select{|a| a.code == chunk_value}.any?}
    when key =~ /(.*)\[stem:(.*)\]/
      chunk_type, chunk_value = $1, $2
      Proc.new{|chunk| (chunk_type == "all" or chunk.type == chunk_type) and chunk.annotations.select{|a| a.stem == chunk_value.stem}.any?}
    when key =~ /(.*)\[(.*)\]/
      chunk_type, chunk_value = $1, $2
      Proc.new{|chunk| (chunk_type == "all" or chunk.type == chunk_type) and chunk.annotations.select{|a| a == chunk_value}.any?}
    else
      key
    end
  end

  def self.transform_index(index)
    new = {}

    index.each do |key,next_index|
      if Hash === next_index
        new[transform_key(key)] = transform_index(next_index)
      else
        new[transform_key(key)] = next_index
      end
    end

    new
  end

  def self.prepare_chunk_patterns(token_trie, patterns)
    token_trie.merge(transform_index(TokenTrieNER.process(patterns)))
  end

  def chunk_patterns(sentences, patterns)
    patterns = case
               when Hash === patterns
                 patterns
               when Array === patterns
                 {:Relation => patterns}
               when String === patterns
                 {:Relation => [patterns]}
               end
    tokenized_patterns = {}

    patterns.each do |key, values|
      tokenized_patterns[key] = values.collect do |v| Token.tokenize(v, /\s+/) end
    end

    PatternRelExt.prepare_chunk_patterns(new_token_trie, tokenized_patterns)
    token_trie.slack = Proc.new{|t| ddd "Slacking #{ t }";  t.type != 'O'}

    sentence_chunks = NLP.gdep_chunk_sentences(sentences)
    sentences.zip(sentence_chunks).collect do |sentence, chunks|
      annotation_index = Segment.index(sentence.annotations)
      chunks.each do |chunk|
        Annotated.annotate(chunk, annotation_index[chunk.range])
      end
      token_trie.match(chunks)
    end
  end
end
