require 'rbbt'
require 'rjb'
require 'rbbt/ner/named_entity'

# Offers a Ruby interface to the Banner Named Entity Recognition Package
# in Java. Banner[http://banner.sourceforge.net/].
class Banner

  Rbbt.add_software "BANNER" => ['','']

  @@JFile = Rjb::import('java.io.File')
  @@SimpleTokenizer = Rjb::import('banner.tokenization.SimpleTokenizer')
  @@CRFTagger = Rjb::import('banner.tagging.CRFTagger')
  @@ParenthesisPostProcessor = Rjb::import('banner.processing.ParenthesisPostProcessor')
  @@HeppleTagger = Rjb::import('dragon.nlp.tool.HeppleTagger')
  @@Sentence = Rjb::import('banner.Sentence')
  @@EngLemmatiser = Rjb::import('dragon.nlp.tool.lemmatiser.EngLemmatiser')



  # The parameters are set to default values, the only one that one
  # might want to change is the modelfile to point to a custom trained
  # one.
  def initialize(modelfile = File.join(Rbbt.find_software('BANNER'), 'gene_model.bin'),
                 lemmadir  = File.join(Rbbt.find_software('BANNER'), 'nlpdata/lemmatiser'),
                 taggerdir = File.join(Rbbt.find_software('BANNER'), 'nlpdata/tagger')
                )

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
  def extract(text)
    text.gsub!(/\n/,' ')
    text.gsub!(/\|/,'/') # Character | gives an error
    sentence = @@Sentence.new(text)
    @tokenizer.tokenize(sentence)
    @tagger.tag(sentence)
    @parenPP.postProcess(sentence)
    tagged = sentence.getSGML

    res = tagged.scan(/<GENE>.*?<\/GENE>/).
      collect{|r|
      r.match(/<GENE>(.*?)<\/GENE>/)
      mention = $1
      mention.sub!(/^\s*/,'')
      mention.sub!(/\s*$/,'')
      NamedEntity.annotate mention
      mention
    }
    res
  end


end


