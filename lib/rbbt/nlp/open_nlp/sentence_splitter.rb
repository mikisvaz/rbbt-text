require 'rbbt'
require 'rjb'
require 'rbbt/ner/segment'
require 'rbbt/resource'

module OpenNLP
  Rbbt.claim Rbbt.software.opt.OpenNLP, :install, Rbbt.share.install.software.OpenNLP.find

  Rbbt.claim Rbbt.software.opt.OpenNLP.models["da-sent.bin"], :url, "http://opennlp.sourceforge.net/models-1.5/de-sent.bin"

  @@FileInputStream = Rjb::import('java.io.FileInputStream')
  @@SentenceModel = Rjb::import('opennlp.tools.sentdetect.SentenceModel')
  @@SentenceDetectorME = Rjb::import('opennlp.tools.sentdetect.SentenceDetectorME')

  def self.sentence_split_detector
    @@sentence_split_detector ||= begin
                              modelIn = @@FileInputStream.new(Rbbt.software.opt.OpenNLP.models["da-sent.bin"].produce.find);

                              model = @@SentenceModel.new(modelIn);
                              modelIn.close()
                              model

                              @@SentenceDetectorME.new(model)
                            end
  end

  def self.sentence_splitter(text)
    last = 0
    sentence_split_detector.sentDetect(text).collect{|sentence|
      start = text.index(sentence, last)
      Segment.setup sentence, start
      last = start + sentence.length
      sentence
    }
  end
end
