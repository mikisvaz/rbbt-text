require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/ner/segment/transformed'
require 'rbbt/ner/segment/named_entity'
require 'rexml/document'
require 'rand'

class TestClass < Test::Unit::TestCase
  def tttest_transform
    a = "This sentence mentions the TP53 gene and the CDK5 protein"
    original = a.dup

    gene1 = "TP53"
    gene1.extend Segment
    gene1.offset = a.index gene1

    gene2 = "CDK5"
    gene2.extend Segment
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
    gene3.extend Segment
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

    Transformed.with_transform(a, [gene1, gene2], "GN") do 
      assert_equal original.gsub(/TP53|CDK5R1/, 'GN'), a
    end

    assert_equal original, a

    Transformed.with_transform(a, [gene1], "GN") do 
      Transformed.with_transform(a, [gene2], "GN") do 
        assert_equal original.gsub(/TP53|CDK5R1/, 'GN'), a
      end
      assert_equal original.gsub(/TP53/, 'GN'), a
    end

    Transformed.with_transform(a, [gene1], "GN") do 
      Transformed.with_transform(a, [gene2], "LONG_GENE_PLACEHOLDER") do 
        assert_equal original.gsub(/TP53/, 'GN').sub('CDK5R1', "LONG_GENE_PLACEHOLDER"), a
      end
      assert_equal original.gsub(/TP53/, 'GN'), a
    end

    assert_equal original, a


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

  def test_html_with_offset
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Segment.setup(a, 10)

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1 
    gene1.offset += 10
    gene1.type = "Gene"

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.offset += 10
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

  def test_cascade_with_overlap_ignored
    a = "This sentence mentions the HDL-C gene and the CDK5R1 protein"

    gene1 = "HDL-C"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.type = "Gene"

    gene2 = "-"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.type = "Dash"

    Transformed.with_transform(a, [gene1], Proc.new{|e| e.html}) do 
      one = a.dup
      Transformed.with_transform(a, [gene2], Proc.new{|e| e.html}) do 
        assert_equal one, a
      end
    end
  end

  def test_error
    a = "Do not have a diagnosis of another hereditary APC resistance/Factor V Leiden, Protein S or C deficiency, prothrombin gene mutation (G20210A), or acquired (lupus anticoagulant) thrombophilic disorder"

    entity1 = "gene"
    entity1.extend NamedEntity
    entity1.offset = a.index entity1
    entity1.type = "Gene"

    entity2 = "prothrombin gene mutation"
    entity2.extend NamedEntity
    entity2.offset = a.index entity2
    entity2.type = "Mutation"

    entity3 = "Protein S or C"
    entity3.extend NamedEntity
    entity3.offset = a.index entity3
    entity3.type = "Gene"

    entity4 = "prothrombin gene mutation"
    entity4.extend NamedEntity
    entity4.offset = a.index entity2
    entity4.type = "Disease"


    Transformed.with_transform(a, [entity1].sort_by{rand}, Proc.new{|e| e.html}) do 
      Transformed.with_transform(a, [entity3, entity2, entity4].sort_by{rand}, Proc.new{|e| e.html}) do 
        assert_nothing_raised{REXML::Document.new "<xml>"+ a + "</xml>"}
      end
    end
   end
end

