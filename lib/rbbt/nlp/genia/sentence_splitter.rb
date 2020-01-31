require 'rbbt/nlp/nlp'
require 'rbbt/ner/segment'
module NLP
  Rbbt.claim Rbbt.software.opt.Geniass, :install, Rbbt.share.install.software.Geniass.find

  def self.returnFeatures(prevWord, delimiter, nextWord)
    if nextWord.match(/__ss__/)
      nw = nextWord.sub(/__ss__/, "")
    else
      nw = nextWord
    end

    str = ""
    # prev. word, next word
    str += "pw_" + prevWord.downcase
    str += "\tnw_" + nw.downcase

    # delimiter
    str += "\td_" + delimiter

    # capitalized first char in next word
    # capital in next word excluding first char.
    if nw[0].chr == nw[0].chr.capitalize
      str += "\tnfc_y"
      nwExcluginFirst = nw[1 ... -1]
      if nwExcluginFirst == nil
        str += "\tnwcef_n"
      elsif nwExcluginFirst.downcase == nwExcluginFirst
        str += "\tnwcef_n"
      else
        str += "\tnwcef_y"
      end
    else
      if nw.downcase == nw
        str += "\tnwcef_n"
      else
        str += "\tnwcef_y"
      end
      str += "\tnfc_n"
    end

    # prev. word capital
    if prevWord.downcase == prevWord
      str += "\tpwc_n"
    else
      str += "\tpwc_y"
    end

    # number in prev. word, in next word
    if prevWord.match(/[0-9]/)
      str += "\tpwn_y"
    else
      str += "\tpwn_n"
    end
    if nw.match(/[0-9]/)
      str += "\tnwn_y"
    else
      str += "\tnwn_n"
    end

    # prev., next word excluding braket, camma, etc.
    prevWordEx = prevWord.gsub(/[()'",\[\]]/, "")
    nwEx = nw.gsub(/[()'",\[\]]/, "")
    str += "\tpwex_" + prevWordEx.downcase
    str += "\tnwex_" + nwEx.downcase

    # bracket or quatation in prev. word
    if prevWord.match(/()'"/)
      str += "\tpwcbq_y"
    else
      str += "\tpwcbq_n"
    end
    # camma in prev., next word
    if prevWord.match(/,/)
      str += "\tpwcc_y"
    else
      str += "\tpwcc_n"
    end
    if nw.match(/,/)
    else
      str += "\tnwcc_n"
    end

    # prev. word + delimiter
    str += "\tpw_" + prevWord + "_d_" + delimiter
    # prev. word ex. +  delimiter + next word ex.
    str += "\tpwex_" + prevWordEx + "_d_" + delimiter + "_nwex_" + nwEx
    #str +=
    #str +=
    #str +=
    str += "\n"
  end

  def self.event_extraction(text)
    events = ""
    marks = ""

    eventCount = 0

    pat = / [^ ]+[.!\?\)\]\"]( +)[^ ]+ /
    for line in text.split(/\n/) do
      while line.match(pat) do
        line.sub!(/ ([^ ]+)([.!\?\)\]\"])( +)([^ ]+) /){
          a, b, d, c = $1, $2, $3, $4
          events << eventCount.to_s  << "\t"
          events << returnFeatures(a, b, c)
          (" " << a << b << "__" << eventCount.to_s << "____" << d << "__" << c << " ")
        }
        eventCount += 1
      end
      marks << line
    end

    [events, marks]
  end

  def self.event_extraction(text)
    events = ""
    marks = ""

    eventCount = 0

    pat = / ([^ ]+)([.!\?\)\]\"])( +)([^ ]+) /
    for line in text.split(/\n/) do
      while line.match(pat) do
        a, b, d, c = $1, $2, $3, $4
        events << eventCount.to_s  << "\t"
        events << returnFeatures(a, b, c)
        line = $` + (" " << a << b << "__" << eventCount.to_s << "____" << d << "__" << c << " ") << $'
        eventCount += 1
      end
      marks << line
    end

    [events, marks]
  end

  def self.process_labels(marked_text, labels)
    out = ""

    count = 0
    text_lines = marked_text.split(/\n/)
    line = text_lines.shift
    for label in labels
      pat = "__" + count.to_s + "__"
      until(line.match(pat)) do
        out << line
        line = text_lines.shift
      end
      splitted = label.chomp.to_i

      line.sub!(pat){
        if splitted == 1
          "__\n__"
        else
          "____"
        end
      }
      line.sub!(/__\n____ +__/, "\n")
      line.sub!(/______( +)__/){
        $1
      }
      count += 1
    end

    out << line

    out << text_lines * ""

    out
  end

  def self.geniass_sentence_splitter_extension(text)
    Rbbt.software.opt.Geniass.produce
    require Rbbt.software.opt.Geniass.ruby["Geniass.so"].find
    geniass = Geniass.new
    if not geniass.geniass_is_loaded
      Misc.in_dir Rbbt.software.opt.Geniass.find do
        geniass.load_geniass
      end
    end

    cleaned = text.gsub("\n",NEW_LINE_MASK)
    events, marks = event_extraction(cleaned)

    labels = events.split(/\n/).collect{|line| 
      geniass.label(line)
    }

    out = process_labels(marks, labels)

    offsets = []

    inTxtStrict = StringIO.new text
    inTxtNew = StringIO.new out.gsub("\n", '|').gsub(NEW_LINE_MASK, "\n")

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

    offsets.collect do |s,e|
      sentence = text[s..e]
      next if sentence.nil?
      Segment.setup sentence, s
      sentence
    end

  end

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
      Segment.setup sentence, s
      sentence
    end
  end

end
