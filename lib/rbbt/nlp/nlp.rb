require 'rbbt'
require 'rbbt/util/tmpfile'
require 'rbbt/ner/annotations'
require 'stanfordparser'

module NLP
  Rbbt.software.opt.StanfordParser.define_as_install Rbbt.share.install.software.StanfordParser.find
  Rbbt.software.opt.StanfordParser.produce

  Rbbt.software.opt.Geniass.define_as_install Rbbt.share.install.software.Geniass.find
  Rbbt.software.opt.Geniass.produce

  def self.geniass_sentence_splitter(text)
    offsets = []

    TmpFile.with_file(text) do |fin|
      TmpFile.with_file do |fout|
        CMD.cmd("cd #{Rbbt.software.opt.Geniass.find}; geniass #{ fin } #{ fout }")

        # Addapted from sentence2standOff.rb in Geniass package
        
        inTxtStrict = Open.open(fin)
        inTxtNew = Open.open(fout)

        marker = "\n"[0]
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
            offsets << [start, finish]
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

      end
    end
    
    offsets.collect do |s,e|
      sentence = text[s..e]
      Segment.annotate sentence, s
      sentence
    end
  end

end

if __FILE__ == $0
  text=<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs) are highly aggressive brain tumors of early childhood poorly responding to therapy. The majority of cases show inactivation of SMARCB1 (INI1, hSNF5, BAF47), a core member of the adenosine triphosphate (ATP)-dependent SWI/SNF chromatin-remodeling complex. We here report the case of a supratentorial AT/RT in a 9-month-old boy, which showed retained SMARCB1 staining on immunohistochemistry and lacked genetic alterations of SMARCB1. Instead, the tumor showed loss of protein expression of another SWI/SNF chromatin-remodeling complex member, the ATPase subunit SMARCA4 (BRG1) due to a homozygous SMARCA4 mutation [c.2032C>T (p.Q678X)]. Our findings highlight the role of SMARCA4 in the pathogenesis of SMARCB1-positive AT/RT and the usefulness of antibodies directed against SMARCA4 in this diagnostic setting.
  EOF
  ddd NLP.geniass_sentence_splitter(text)
end
