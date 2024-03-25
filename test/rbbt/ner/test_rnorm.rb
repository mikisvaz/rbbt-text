require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/ner/rnorm'
require 'rbbt/util/open'
require 'rbbt/util/tmpfile'
require 'test/unit' 
 
class TestRNORM < Test::Unit::TestCase
 
  def setup 
    tmp = TmpFile.tmp_file("test-rnorm-")
    lexicon =<<-EOT
S000000029	YAL031C	GIP4	FUN21
S000000030	YAL032C	PRP45	FUN20
S000000031	YAL033W	POP5	FUN53 
S000000374	YBR170C	NPL4	HRD4
S000000375	GENE1	BBB	CCC
S000000376	AAA	GENE1	DDD
	EOT

    Open.write(tmp, lexicon)

    @norm = Normalizer.new(tmp) 
    FileUtils.rm tmp
  end

  def test_match
     assert_equal(["S000000029"], @norm.match("FUN21"))
     assert_equal(["S000000030", "S000000029", "S000000031"].sort, @norm.match("FUN").sort)
     assert_equal(["S000000030", "S000000029", "S000000031"].sort, @norm.match("FUN 2").sort)
     assert_equal(["S000000029"].sort, @norm.match("FUN 21").sort) 
     assert_equal([], @norm.match("Non-sense"))
     assert_equal(["S000000029", "S000000374"], @norm.match("GER4"))
  end 

  def test_select
    assert_equal(["S000000029"], @norm.select(["S000000030", "S000000029", "S000000031"],"FUN 21"))
  end

  def test_resolve
    assert_equal(["S000000029"], @norm.resolve("FUN 21"))
  end

  def test_order
    assert_equal(["S000000375"], @norm.resolve("GENE1"))
  end

  def test_token_evaluate
    assert @norm.token_evaluate("PDGFRA","PDGFRalpha") > 0
  end

end
