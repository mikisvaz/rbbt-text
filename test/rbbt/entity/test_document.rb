require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')

require 'rbbt/workflow'
require 'rbbt/entity'
Workflow.require_workflow "Genomics"

Workflow.require_workflow "TextMining"

require 'rbbt/entity/pmid'
require 'rbbt/entity/document'
require 'test/unit'


module Document
  self.corpus = Persist.open_tokyocabinet("/tmp/corpus", false, :string, "BDB")

  property :banner => :single do |*args|
    normalize, organism = args
    TextMining.job(:gene_mention_recognition, "Factoid", :text => text, :method => :banner, :normalize => normalize, :organism => organism).exec.each{|e| SegmentWithDocid.setup(e, self.docid)}
  end

  property :abner => :single do |*args|
    normalize, organism = args
    TextMining.job(:gene_mention_recognition, "Factoid", :text => text, :method => :abner, :normalize => normalize, :organism => organism).exec.each{|e| SegmentWithDocid.setup(e, self.docid)}
  end

  persist :abner, :annotations, :dir => Rbbt.tmp.test.find(:user).entity_property
end

class TestDocument < Test::Unit::TestCase
  def _test_pmid
    pmid = "21904853"
    PMID.setup(pmid)

    assert_match /^PMID/, pmid.id
    assert_match /TET2/, pmid.text
  end

  def _test_abner
    pmid = "21904853"
    PMID.setup(pmid)

    genes = pmid.abner.reject{|ne| ne.offset.nil?}
    genes.each do |ne|
      orig = ne
      orig_range = ne.range
      ne.mask
      assert ne.masked?
      assert ne =~ /^MASKED/
      assert_equal orig_range, ne.range
      assert_equal ne, ne.unmask
    end
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


