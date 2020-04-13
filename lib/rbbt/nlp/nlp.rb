require 'rbbt'
require 'rbbt/util/tmpfile'
require 'rbbt/persist'
require 'rbbt/resource'
require 'rbbt/text/segment'
require 'rbbt/text/segment/segmented'
require 'rbbt/nlp/genia/sentence_splitter'
require 'digest/md5'


module NLP

  extend LocalPersist
  self.local_persist_dir = '/tmp/crap'

  #Rbbt.software.opt.StanfordParser.define_as_install Rbbt.share.install.software.StanfordParser.find
  #Rbbt.software.opt.StanfordParser.produce

  Rbbt.claim Rbbt.software.opt.Gdep, :install, Rbbt.share.install.software.Gdep.find

  NEW_LINE_MASK = "\t\t \t  \t"

  module GdepToken
    extend Annotation
    include Segment
    self.annotation :num, :lemma, :chunk, :pos, :bio, :link, :dep
  end

  module GdepChunk
    extend Annotation
    include Segment
    self.annotation :type, :parts
  end

  def self.merge_vp_chunks(chunk_list)
    vp = nil
    new_chunks = []
    chunk_list.each do |chunk|
      if chunk.type =~ /^VP/
        if vp.nil?
          vp = chunk
        else
          vp << chunk
          vp.parts.concat chunk.parts
        end
      else
        new_chunks << vp if not vp.nil?
        new_chunks << chunk
        vp = nil
      end
    end

    new_chunks
  end

  def self.gdep_chunks(sentence, segment_list)
    chunks = []

    chunk_start = "B"[0]
    chunk_inside = "I"[0]

    last = GdepToken.setup("LW")

    chunk_segments = []
    segment_list.each do |segment|
      if segment.chunk[0] == chunk_inside and not segment.offset.nil?
        chunk_segments << segment
      else
        if chunk_segments.any?
          cstart = chunk_segments.first.offset
          cend = chunk_segments.last.end
          chunk = sentence[cstart..cend]
          GdepChunk.setup(chunk, cstart, last.chunk.sub(/^.-/,''), chunk_segments)
          chunks << chunk
        end

        if segment.offset.nil?
          chunk_segments = []
        else
          chunk_segments = [segment]
        end
      end
      last = segment
    end

    if chunk_segments.any?
      cstart = chunk_segments.first.offset
      cend = chunk_segments.last.end
      chunk = sentence[cstart..cend]
      GdepChunk.setup(chunk, cstart, last.chunk.sub(/^.-/,''), chunk_segments)
      chunks << chunk
    end

      
    chunks
  end

  def self.gdep_parse_sentences(sentences)
    sentences = Array === sentences ? sentences : [sentences]

    input = sentences.collect{|sentence| sentence.gsub(/\n/, NEW_LINE_MASK)} * "\n"
    sentence_tokens = TmpFile.with_file(input) do |fin|
      out = local_persist(Digest::MD5.hexdigest(input), :Chunks, :string) do
        CMD.cmd("cd #{Rbbt.software.opt.Gdep.find}; ./gdep #{ fin }").read
      end

      out.split(/^$/).collect do |sentence|
        tokens = sentence.split(/\n/).collect do |line|
          next if line.empty?
          num, token, lemma, chunk, pos, bio, link, dep = line.split(/\t/)
          GdepToken.setup(token, nil, num, lemma, chunk, pos, bio, link, dep)
        end.compact
      end
    end

    sentences.zip(sentence_tokens).collect do |sentence, tokens|
      Segment.align(sentence, tokens)
    end
  end


  def self.gdep_parse_sentences_extension(sentences)
    require Rbbt.software.opt.Gdep.ruby["Gdep.so"].find
    gdep = Gdep.new
    if not gdep.gdep_is_loaded
      Misc.in_dir Rbbt.software.opt.Gdep.find do
        gdep.load_gdep 
      end
    end

    sentences = Array === sentences ? sentences : [sentences]

    sentence_tokens = sentences.collect{|sentence|
      Gdep.new.tag(sentence).split(/\n/).collect do |line|
        next if line.empty?
        token, lemma, pos, chunk = line.split(/\t/)
        GdepToken.setup(token, nil, nil, lemma, chunk, pos)
        token
      end.compact
    }

    sentences.zip(sentence_tokens).collect do |sentence, tokens|
      Segment.align(sentence, tokens)
      tokens
    end
  end

  def self.gdep_chunk_sentences(sentences)
    sentences = Array === sentences ? sentences : [sentences]
    NLP.gdep_parse_sentences_extension(sentences).zip(sentences).collect do |segment_list, sentence|
      chunk_list = NLP.gdep_chunks(sentence, segment_list)
      NLP.merge_vp_chunks(chunk_list)
    end
  end
end

if __FILE__ == $0
  Log.severity = 0
  Rbbt.software.opt.Gdep.produce
end
