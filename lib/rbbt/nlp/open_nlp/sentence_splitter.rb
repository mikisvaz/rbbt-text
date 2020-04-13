require 'rbbt'
require 'rjb'
require 'rbbt/text/segment'
require 'rbbt/resource'

module OpenNLP
  Rbbt.claim Rbbt.software.opt.OpenNLP, :install, Rbbt.share.install.software.OpenNLP.find


  Rbbt.claim Rbbt.software.opt.OpenNLP.models["da-sent.bin"], :url, "http://opennlp.sourceforge.net/models-1.5/de-sent.bin"

  MAX = 5

  def self.sentence_split_detector
    @@sentence_split_detector ||= begin
                                    Rbbt.software.opt.OpenNLP.produce
                                    Rbbt.software.opt.OpenNLP.models["da-sent.bin"].produce

                                    @@FileInputStream = Rjb::import('java.io.FileInputStream')
                                    @@SentenceModel = Rjb::import('opennlp.tools.sentdetect.SentenceModel')
                                    @@SentenceDetectorME = Rjb::import('opennlp.tools.sentdetect.SentenceDetectorME')

                                    modelIn = @@FileInputStream.new(Rbbt.software.opt.OpenNLP.models["da-sent.bin"].produce.find);

                                    model = @@SentenceModel.new(modelIn);
                                    modelIn.close()
                                    model

                                    @@SentenceDetectorME.new(model)
                                  end
  end

  def self.sentence_splitter(text)
    return [] if text.nil? or text.empty?

    text = Misc.to_utf8(text)
    last = 0
    begin
      sentence_split_detector = self.sentence_split_detector
      
      sentences = nil
      TmpFile.with_file do |tmpfile|
        start_time = Time.now

        begin
          pid = Process.fork do
            sent = sentence_split_detector.sentDetect(text)
            Open.write(tmpfile, sent * "#OpenNLP:SENTENCE#")
          end

          while not Process.waitpid(pid)
            if Time.now - start_time > MAX
              Process.kill(9, pid)
              raise "Taking to long (> #{MAX} seconds)"
            end
            sleep 0.1
          end

          begin
            Process.waitpid(pid)
          end
        rescue Errno::ECHILD
        end

        sentences = Open.read(tmpfile).split("#OpenNLP:SENTENCE#")
      end

      sentences.collect{|sentence|
        sentence = Misc.to_utf8(sentence)
        start = text.index(sentence, last)
        Segment.setup sentence, start
        last = start + sentence.length - 1
        sentence
      }
    rescue Exception
      raise $!
      raise "Sentence splitter raised exception: #{$!.message}"
    end
  end
end
