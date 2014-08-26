require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/entity'
require 'rbbt/ner/finder'
require 'rbbt/ner/finder'
require 'rbbt/sources/organism'
require 'rbbt/sources/kegg'
require 'rbbt/sources/NCI'

class TestFinder < Test::Unit::TestCase

  def test_namespace_and_format
    f = Finder.new(CMD.cmd("head -n 1000", :in => Open.open(Organism.identifiers(Organism.default_code("Hsa")).produce.find)))
    assert_equal "Hsa", f.instances.first.namespace
    assert_equal "Ensembl Gene ID", f.instances.first.format
  end

  def test_find
    f = Finder.new(Organism.lexicon(Organism.default_code("Hsa")), :grep => ["SF3B1"])

    assert_equal "ENSG00000115524", f.find("SF3B1").first
    if defined? Entity
      ddd f.find("SF3B1").first.info
      assert_equal "Ensembl Gene ID", f.find("SF3B1").first.format
    end
  end

  def test_find
    f = Finder.new(Organism.lexicon(Organism.default_code("Hsa")), :grep => ["RASGRF2"])

    assert f.find("RAS").include? "ENSG00000113319"
  end

end
