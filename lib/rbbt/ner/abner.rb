require 'rbbt'
require 'rjb'
require 'rbbt/ner/segment'
require 'rbbt/resource'
require 'rbbt/ner/NER'

# Offers a Ruby interface to the Abner Named Entity Recognition Package
# in Java Abner[http://www.cs.wisc.edu/~bsettles/abner/].
class Abner < NER

  Rbbt.claim Rbbt.software.opt.ABNER, :install, Rbbt.share.install.software.ABNER.find

  @@JFile   = Rjb::import('java.io.File')
  @@Tagger  = Rjb::import('abner.Tagger')
  @@Trainer = Rjb::import('abner.Trainer')

  # If modelfile is present a custom trained model can be used,
  # otherwise, the default BioCreative model is used.
  def initialize(modelfile=nil)
    if modelfile == nil         
      @tagger = @@Tagger.new(@@Tagger.BIOCREATIVE)
    else                
      @tagger = @@Tagger.new(@@JFile.new(modelfile))
    end
  end

  # Given a chunk of text, it finds all the mentions appearing in it. It
  # returns all the mentions found, regardless of type, to be coherent
  # with the rest of NER packages in Rbbt.
  def match(text)
    return [] if text.nil? or text.empty?

    res = @tagger.getEntities(text)
    types = res[1]
    strings = res[0]

    global_offset = 0
    strings.zip(types).collect do |mention, type| 
      mention = mention.to_s; 
      offset = text.index(mention)
      if offset.nil?
        NamedEntity.setup(mention, nil, type.to_s)
      else
        NamedEntity.setup(mention, offset + global_offset, type.to_s)
        text = text[offset + mention.length..-1]
        global_offset += offset + mention.length
      end

      mention
    end
  end

end
