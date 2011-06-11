require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/ner/annotations/transformed'
require 'rbbt/ner/annotations/named_entity'

class TestClass < Test::Unit::TestCase
  def test_transform
    a = "This sentence mentions the TP53 gene and the CDK5 protein"
    original = a.dup

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1

    gene2 = "CDK5"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2

    assert_equal gene1, a[gene1.range]
    assert_equal gene2, a[gene2.range]
    
    c = a.dup

    c[gene2.range] = "GN"
    assert_equal c, Transformed.transform(a,[gene2], "GN")
    c[gene1.range] = "GN"
    assert_equal c, Transformed.transform(a,[gene1], "GN")

    assert_equal gene2.offset, a.transformation_offset_differences.first.first.first
    assert_equal gene1.offset, a.transformation_offset_differences.last.first.first


    gene3 = "GN gene"
    gene3.extend NamedEntity
    gene3.offset = a.index gene3

    assert_equal gene3, a[gene3.range]

    a.restore([gene3])
    assert_equal original, a
    assert_equal "TP53 gene", a[gene3.range]

  end

  def test_with_transform
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    original = a.dup

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2

    Transformed.with_transform(a, [gene1], "GN") do 
      assert_equal original.sub("TP53", 'GN'), a
    end
    assert_equal original, a

    Transformed.with_transform(a, [gene1,gene2], "GN") do 
      assert_equal original.gsub(/TP53|CDK5R1/, 'GN'), a
    end
    assert_equal original, a

    Transformed.with_transform(a, [gene1], "GN") do 
      Transformed.with_transform(a, [gene2], "GN") do 
        assert_equal original.gsub(/TP53|CDK5R1/, 'GN'), a
      end
      assert_equal original.gsub(/TP53/, 'GN'), a
    end
    assert_equal original, a

    exp1, exp2 = nil, nil
    expanded_genes = Transformed.with_transform(a, [gene1,gene2], "GN") do 
      exp1 = "GN gene"
      exp1.extend NamedEntity
      exp1.offset = a.index exp1
      exp2 = "GN protein"
      exp2.extend NamedEntity
      exp2.offset = a.index exp2

      [exp1, exp2]
    end
    assert_equal original, a

    assert_equal "TP53 gene", exp1
    assert_equal "CDK5R1 protein", exp2
  end

  def test_html
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.type = "Gene"

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.type = "Protein"

    Transformed.with_transform(a, [gene1,gene2], Proc.new{|e| e.html}) do 
      assert_equal "This sentence mentions the <span class='Entity' attr-entity-type='Gene'>TP53</span> gene and the <span class='Entity' attr-entity-type='Protein'>CDK5R1</span> protein", a
    end
  end

  def test_overlap
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.type = "Gene"

    gene2 = "TP53 gene"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.type = "Expanded Gene"

    assert_equal [gene1], Segment.overlaps(Segment.sort([gene1,gene2]))

    Transformed.with_transform(a, [gene1], Proc.new{|e| e.html}) do 
      assert_equal "This sentence mentions the <span class='Entity' attr-entity-type='Gene'>TP53</span> gene and the CDK5R1 protein", a
      Transformed.with_transform(a, [gene2], Proc.new{|e| e.html}) do 
        assert_equal "This sentence mentions the <span class='Entity' attr-entity-type='Expanded Gene'><span class='Entity' attr-entity-type='Gene'>TP53</span> gene</span> and the CDK5R1 protein", a
      end
    end
  end
end

