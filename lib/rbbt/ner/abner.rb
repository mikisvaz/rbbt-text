require 'rbbt'
require 'rjb'
require 'rbbt/resource'
require 'rbbt/segment'
require 'rbbt/ner/NER'

# Offers a Ruby interface to the Abner Named Entity Recognition Package
# in Java Abner[http://www.cs.wisc.edu/~bsettles/abner/].
class Abner < NER

  Rbbt.claim Rbbt.software.opt.ABNER, :install, Rbbt.share.install.software.ABNER.find

  def self.init
    Rbbt.software.opt.ABNER.produce
    @@JFile   ||= Rjb::import('java.io.File')
    @@Tagger  ||= Rjb::import('abner.Tagger')
    @@Trainer ||= Rjb::import('abner.Trainer')
  end

  # If modelfile is present a custom trained model can be used,
  # otherwise, the default BioCreative model is used.
  def initialize(modelfile=nil)
    Abner.init
    if modelfile == nil         
      @tagger = @@Tagger.new(@@Tagger.BIOCREATIVE)
    else                
      @tagger = @@Tagger.new(@@JFile.new(modelfile))
    end
  end

  # Given a chunk of text, it finds all the mentions appearing in it. It
  # returns all the mentions found, regardless of type, to be coherent
  # with the rest of NER packages in Rbbt.
  def match(text, fix_encode = true)
    return [] if text.nil? or text.empty?

    text = text.encode('utf-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '') if fix_encode
    res = @tagger.getEntities(text)
    types = res[1]
    strings = res[0]

    docid = Misc.digest(text)
    global_offset = 0
    strings.zip(types).collect do |mention, type| 
      mention = mention.to_s; 
      offset = text.index(mention)
      if offset.nil?
        NamedEntity.setup(mention, :docid => docid, :entity_type => type)
      else
        NamedEntity.setup(mention, :offset => offset + global_offset, :docid => docid, :entity_type => type.to_s)
        text = text[offset + mention.length..-1]
        global_offset += offset + mention.length
      end

      mention
    end
  end

end
