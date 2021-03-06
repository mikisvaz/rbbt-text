require 'rbbt'
require 'rjb'
require 'rbbt/ner/NER'
require 'rbbt/segment'

# Offers a Ruby interface to the Banner Named Entity Recognition Package
# in Java. Banner[http://banner.sourceforge.net/].
class Banner < NER

  Rbbt.claim Rbbt.software.opt.BANNER, :install, Rbbt.share.install.software.BANNER.find

  def self.init
    Rbbt.software.opt.BANNER.produce
    @@JFile                    ||= Rjb::import('java.io.File')
    @@SimpleTokenizer          ||= Rjb::import('banner.tokenization.SimpleTokenizer')
    @@CRFTagger                ||= Rjb::import('banner.tagging.CRFTagger')
    @@ParenthesisPostProcessor ||= Rjb::import('banner.processing.ParenthesisPostProcessor')
    @@HeppleTagger             ||= Rjb::import('dragon.nlp.tool.HeppleTagger')
    @@Sentence                 ||= Rjb::import('banner.Sentence')
    @@EngLemmatiser            ||= Rjb::import('dragon.nlp.tool.lemmatiser.EngLemmatiser')
  end



  # The parameters are set to default values, the only one that one
  # might want to change is the modelfile to point to a custom trained
  # one.
  def initialize(modelfile = Rbbt.software.opt.BANNER["gene_model.bin"].find,
                 lemmadir  = Rbbt.software.opt.BANNER.nlpdata.lemmatiser.find,
                 taggerdir = Rbbt.software.opt.BANNER.nlpdata.tagger.find
                )
    Banner.init

    @tokenizer = @@SimpleTokenizer.new

    model = @@JFile.new(modelfile)
    lemma =  @@EngLemmatiser.new(lemmadir,false,true)
    helper =  @@HeppleTagger.new(taggerdir)

    # The next lines are needed to avoid colisions with
    # metraprograming that could define load (activesupport in
    # particular :@ ). RJB seems to call java on method missing
    class << @@CRFTagger
      if method_defined? :load 
        undef_method :load 
      end
    end  

    @tagger    = @@CRFTagger.load( model, lemma, helper)
    @parenPP   = @@ParenthesisPostProcessor.new()
  end

  
  # Returns an array with the mention found in the provided piece of
  # text.
  def match(text)
    return [] if text.nil? 
    text = text.dup if text.frozen?
    text.gsub!(/\n/,' ')
    text.gsub!(/\|/,'/') # Character | gives an error
    return [] if text.strip.empty? 
    text = text.encode('utf-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '')
    sentence = @@Sentence.new(text)

    @tokenizer.tokenize(sentence)
    @tagger.tag(sentence)
    @parenPP.postProcess(sentence)
    tagged = sentence.getSGML

    docid = Misc.digest text
    res = tagged.scan(/<GENE>.*?<\/GENE>/).
      collect{|r|
      r.match(/<GENE>(.*?)<\/GENE>/)
      mention = $1
      mention.sub!(/^\s*/,'')
      mention.sub!(/\s*$/,'')
      offset = text.index(mention)
      NamedEntity.setup(mention, :offset => offset, :docid => docid, :entity_type => 'GENE')
      mention
    }
    res
  end


end



