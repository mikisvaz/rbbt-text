require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/ner/segment/segmented'

class TestClass < Test::Unit::TestCase
  def test_split
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend Segment
    gene1.offset = a.index gene1

    gene2 = "CDK5R1"
    gene2.extend Segment
    gene2.offset = a.index gene2

    gene3 = "TP53 gene"
    gene3.extend Segment
    gene3.offset = a.index gene3

    Segmented.setup(a, [gene2, gene1, gene3])
    assert_equal ["This sentence mentions the ", gene3, " and the ", gene2, " protein"], a.split_segments
  end
end
