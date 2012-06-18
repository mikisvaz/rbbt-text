require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/entity'
require 'rbbt/entity/pmid'
require 'rbbt/entity/document'
require 'test/unit'

require 'rbbt/workflow'

Workflow.require_workflow "TextMining"

module Document
  self.corpus = Persist.open_tokyocabinet("/tmp/corpus", false, :string, "BDB")

  property :banner => :single do |*args|
    normalize, organism = args
    TextMining.job(:gene_mention_recognition, "Factoid", :text => text, :method => :banner, :normalize => normalize, :organism => organism).exec
  end

  property :abner => :single do |*args|
    normalize, organism = args
    TextMining.job(:gene_mention_recognition, "Factoid", :text => text, :method => :banner, :normalize => normalize, :organism => organism).exec
  end

  persist :abner, :annotations
end

class TestDocument < Test::Unit::TestCase
  def test_pmid
    pmid = "21904853"
    PMID.setup(pmid)

    assert_match /^PMID/, pmid.id
    assert_match /TET2/, pmid.text
  end

  def test_abner
    pmid = "21904853"
    PMID.setup(pmid)

    assert pmid.abner.include? "TET2"
  end

  def test_free_text
    text = "Free text including a mention to TET2."
    Document.setup(text)

    assert text.abner.include? "TET2"
    
    docid = text.docid
    assert_match /TET2/, Document.setup(docid).text

    assert Document.setup(docid).abner.include? "TET2"
  end
end


