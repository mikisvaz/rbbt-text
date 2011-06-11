require 'rbbt'
require 'rbbt/util/tmpfile'
require 'rbbt/util/persistence'
require 'rbbt/util/resource'
require 'rbbt/ner/annotations'
require 'rbbt/ner/annotations/annotated'
require 'digest/md5'

module NLP
  extend LocalPersist

  self.local_persistence_dir = Resource.caller_lib_dir(__FILE__)


  #Rbbt.software.opt.StanfordParser.define_as_install Rbbt.share.install.software.StanfordParser.find
  #Rbbt.software.opt.StanfordParser.produce

  Rbbt.software.opt.Geniass.define_as_install Rbbt.share.install.software.Geniass.find
  Rbbt.software.opt.Geniass.produce

  Rbbt.software.opt.Gdep.define_as_install Rbbt.share.install.software.Gdep.find
  Rbbt.software.opt.Gdep.produce

  NEW_LINE_MASK = "\t\t \t  \t"

  def self.geniass_sentence_splitter(text)
    offsets = []

    cleaned = text.gsub("\n",NEW_LINE_MASK)
    TmpFile.with_file(cleaned) do |fin|
      TmpFile.with_file do |fout|
        CMD.cmd("cd #{Rbbt.software.opt.Geniass.find}; ./geniass #{ fin } #{ fout }")

        
        Open.write(fin, Open.read(fin).gsub(NEW_LINE_MASK, "\n"))
        Open.write(fout, Open.read(fout).gsub("\n", '|').gsub(NEW_LINE_MASK, "\n"))
        # Addapted from sentence2standOff.rb in Geniass package

        inTxtStrict = Open.open(fin)
        inTxtNew = Open.open(fout)

        marker = "|"[0]
        position = 0
        sentenceCount = 1
        target = ''
        targetNew = ''
        start = 0
        finish = 0

        while(!inTxtNew.eof?) do
          targetNew = inTxtNew.getc
          target = inTxtStrict.getc
          position += 1
          if targetNew == marker
            sentenceCount += 1
            finish = position - 1
            offsets << [start, finish] if finish - start > 10
            if targetNew == target
              start = position
            else
              targetNew = inTxtNew.getc
              while targetNew != target do
                target = inTxtStrict.getc
                position += 1
              end
              start = position - 1
            end
          end
        end

        finish = position - 1
        offsets << [start, finish] if finish > start

        inTxtStrict.close
        inTxtNew.close
      end
    end

    offsets.collect do |s,e|
      sentence = text[s..e]
      next if sentence.nil?
      #sentence.gsub!(NEW_LINE_MASK, "\n")
      Segment.annotate sentence, s
      sentence
    end
  end

  module GdepToken
    include Segment
    attr_accessor :num, :token, :lemma, :chunk, :pos, :bio, :link, :dep

    def self.annotate(token, offset = nil, num = nil, lemma = nil, chunk = nil, pos = nil, bio = nil, link = nil, dep = nil)
      token.extend GdepToken

      token.offset = offset
      token.num = num
      token.lemma = lemma
      token.chunk = chunk
      token.pos = pos
      token.bio = bio
      token.link = link
      token.dep = dep

      token
    end
  end

  module GdepChunk
    include Segment
    include Annotated

    attr_accessor :type

    def self.annotate(string, offset = nil, type = nil, annotations = nil)
      string.extend GdepChunk

      string.offset = offset
      string.type = type
      string.annotations = annotations
      
      string
    end
  end

  def self.merge_vp_chunks(chunk_list)
    vp = nil
    new_chunks = []
    chunk_list.each do |chunk|
      if chunk.type =~ /^VP/
        if vp.nil?
          vp = chunk
        else
          ddd "Joining #{ chunk } to #{ vp * " : "}"
          vp << chunk
          vp.annotations.concat chunk.annotations
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
    last = GdepToken.annotate("LW")
    chunk_segments = []
    segment_list.each do |segment|
      if segment.chunk[0] == chunk_inside
        chunk_segments << segment
      else
        if chunk_segments.any?
          cstart = chunk_segments.first.offset
          cend = chunk_segments.last.end
          chunk = sentence[cstart..cend]
          GdepChunk.annotate(chunk, cstart, last.chunk.sub(/^.-/,''), chunk_segments)
          chunks << chunk
        end
        chunk_segments = [segment]
      end
      last = segment
    end

    chunks
  end

  def self.gdep_parse_sentences(sentences)
    sentences = Array === sentences ? sentences : [sentences]

    input = sentences.collect{|sentence| sentence.gsub(/\n/, NEW_LINE_MASK)} * "\n"
    sentence_tokens = TmpFile.with_file(input) do |fin|
      out = local_persist(Digest::MD5.hexdigest(input), :Sentences, :string) do
        CMD.cmd("cd #{Rbbt.software.opt.Gdep.find}; ./gdep #{ fin }").read
      end
      out.split(/^$/).collect do |sentence|
        tokens = sentence.split(/\n/).collect do |line|
          next if line.empty?
          num, token, lemma, chunk, pos, bio, link, dep = line.split(/\t/)
          GdepToken.annotate(token, nil, num, lemma, chunk, pos, bio, link, dep)
        end.compact
      end
    end

    sentences.zip(sentence_tokens).collect do |sentence, tokens|
      Segment.align(sentence, tokens)
    end
  end

  def self.gdep_chunk_sentences(sentences)
    sentences = Array === sentences ? sentences : [sentences]
    NLP.gdep_parse_sentences(sentences).zip(sentences).collect do |segment_list, sentence|
      chunk_list = NLP.gdep_chunks(sentence, segment_list)
      new_chunk_list = NLP.merge_vp_chunks(chunk_list)
    end
  end
end
