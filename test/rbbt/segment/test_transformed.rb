require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/segment/transformed'
require 'rbbt/segment/named_entity'
require 'rexml/document'

class TestTransformed < Test::Unit::TestCase

  def setup
    @text = <<-EOF
More recently, PPAR activators were shown to inhibit the activation of inflammatory response genes (such as IL-2, IL-6, IL-8, TNF alpha and metalloproteases) by negatively interfering with the NF-kappa B, STAT and AP-1 signalling pathways in cells of the vascular wall.
    EOF

    @entities = ["PPAR", "IL-2", "IL-6", "IL-8", "TNF alpha", "NF-kappa B", "AP-1", "STAT"].collect do |literal|
      NamedEntity.setup(literal, :offset => @text.index(literal))
    end
  end

  def test_transform
    text = <<-EOF
More recently, PPAR activators were shown to inhibit the activation of inflammatory response genes (such as IL-2, IL-6, IL-8, TNF alpha and metalloproteases) by negatively interfering with the NF-kappa B, STAT and AP-1 signalling pathways in cells of the vascular wall.
    EOF

    entities = ["PPAR", "IL-2", "IL-6", "IL-8", "TNF alpha", "NF-kappa B", "AP-1", "STAT"].reverse.collect do |literal|
      NamedEntity.setup(literal, :offset => text.index(literal))
    end

    Transformed.transform(text, entities, Proc.new{|e| "[" + e.upcase + "]" }) 
    assert text.include? "such as [IL-2]"
  end

  def test_with_transform
    text = <<-EOF
More recently, PPAR activators were shown to inhibit the activation of inflammatory response genes (such as IL-2, IL-6, IL-8, TNF alpha and metalloproteases) by negatively interfering with the NF-kappa B, STAT and AP-1 signalling pathways in cells of the vascular wall.
    EOF

    entities = ["PPAR", "IL-2", "IL-6", "IL-8", "TNF alpha", "NF-kappa B", "AP-1", "STAT"].reverse.collect do |literal|
      NamedEntity.setup(literal, :offset => text.index(literal))
    end

    Transformed.with_transform(text, entities, Proc.new{|e| "[" + e.upcase + "]" }) do 
      assert text.include? "such as [IL-2]"
    end
  end

  def test_with_transform_2
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

  def test_with_transform_sentences
    a = "This first sentence mentions Bread. This sentence mentions the TP53 gene and the CDK5R1 protein"
    original = a.dup

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2

    bread = "Bread"
    bread.extend NamedEntity
    bread.offset = a.index bread

    sentences = Segment.align(a, a.split(". "))

    Transformed.with_transform(sentences[1], [gene1, gene2, bread], "GN") do
      assert sentences[1].include?("GN gene and the GN protein")
    end

    Transformed.with_transform(sentences[0], [gene1, gene2, bread], "BR") do
      assert sentences[0].include?("first sentence mentions BR")
    end


  end

  def test_html
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.entity_type = "Gene"

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.entity_type = "Protein"

    Transformed.with_transform(a, [gene1,gene2], Proc.new{|e| e.html}) do 
      assert_equal "This sentence mentions the <span class='Entity' attr-entity-type='Gene' title='Gene'>TP53</span> gene and the <span class='Entity' attr-entity-type='Protein' title='Protein'>CDK5R1</span> protein", a
    end
  end

  def test_html_with_offset
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"
    Segment.setup(a, 10)

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1 
    gene1.offset += 10
    gene1.entity_type = "Gene"

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.offset += 10
    gene2.entity_type = "Protein"

    Transformed.with_transform(a, [gene1,gene2], Proc.new{|e| e.html}) do 
      assert_equal "This sentence mentions the <span class='Entity' attr-entity-type='Gene' title='Gene'>TP53</span> gene and the <span class='Entity' attr-entity-type='Protein' title='Protein'>CDK5R1</span> protein", a
    end
  end

  def test_overlap
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.entity_type = "Gene"

    gene2 = "TP53 gene"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.entity_type = "Expanded Gene"

    assert_equal [gene1], Segment.overlaps(Segment.sort([gene1,gene2]))

    Transformed.with_transform(a, [gene1], Proc.new{|e| e.html}) do 
      assert_equal "This sentence mentions the <span class='Entity' attr-entity-type='Gene' title='Gene'>TP53</span> gene and the CDK5R1 protein", a
      Transformed.with_transform(a, [gene2], Proc.new{|e| e.html}) do 
        assert_equal "This sentence mentions the <span class='Entity' attr-entity-type='Expanded Gene' title='Expanded Gene'><span class='Entity' attr-entity-type='Gene' title='Gene'>TP53</span> gene</span> and the CDK5R1 protein", a
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

  def test_nested_transform
    a = "This sentence mentions the TP53 gene and the CDK5R1 protein"

    gene1 = "TP53"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.type = "Gene"

    gene2 = "CDK5R1"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.type = "Protein"

    Transformed.with_transform(a, [gene1,gene2], "[G]") do 
      assert_equal "This sentence mentions the [G] gene and the [G] protein", a
    end
    Transformed.with_transform(a, [gene1], "[G1]") do 
      Transformed.with_transform(a, [gene2], "[G2]") do 
        assert_equal "This sentence mentions the [G1] gene and the [G2] protein", a
      end
    end
    Transformed.with_transform(a, [gene2], "[G2]") do 
      Transformed.with_transform(a, [gene1], "[G1]") do 
        assert_equal "This sentence mentions the [G1] gene and the [G2] protein", a
      end
    end
  end

  def test_offset_transform
    a = "ILF can bind to purine-rich regulatory motifs such as the human T-cell leukemia virus-long terminal region and the interleukin-2 promoter."

    gene1 = "ILF"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.type = "Gene"

    gene2 = "interleukin-2"
    gene2.extend NamedEntity
    gene2.offset = a.index gene2
    gene2.type = "Protein"

    Transformed.with_transform(a, [gene1,gene2], "[G]") do 
      assert_equal "[G] can bind to purine-rich regulatory motifs such as the human T-cell leukemia virus-long terminal region and the [G] promoter.", a
    end

    offset = 100
    a = Segment.setup(a, :offset => offset)
    gene1.offset += offset
    gene2.offset += offset
    Transformed.with_transform(a, [gene1,gene2], "[G]") do 
      assert_equal "[G] can bind to purine-rich regulatory motifs such as the human T-cell leukemia virus-long terminal region and the [G] promoter.", a
    end

  end

  def test_by_sentence
    a = "This is a first sentences. ILF can bind to purine-rich regulatory motifs such as the human T-cell leukemia virus-long terminal region and the interleukin-2 promoter."

    sentence_pos = a.index('.')+2
    sentence = a[sentence_pos..-1]
    Segment.setup sentence, sentence_pos

    gene1 = "ILF"
    gene1.extend NamedEntity
    gene1.offset = a.index gene1
    gene1.type = "Gene"

    Transformed.with_transform(sentence, [gene1], "[G]") do 
      assert_equal sentence.sub("ILF", "[G]"), sentence
    end
  end

  def test_collisions
    text =<<-EOF.chomp
This is another sentence. Protein (nsp1), helicase (nsp13).
    EOF

    sentence_pos = text.index(".") + 2
    sentence = Segment.setup(text[sentence_pos..-1], sentence_pos)

    viral = %w(nsp1 nsp13)
    human = %w(helicase)

    viral = viral.collect do |e|
      next unless text.index(e)
      NamedEntity.setup(e, text.index(e), "VirGene")
    end.compact

    human = human.collect do |e|
      next unless text.index(e)
      NamedEntity.setup(e, text.index(e), "HumGene")
    end

    clean = human.reject{|s| s.overlaps(viral).any?}

    Transformed.with_transform(sentence, viral, Proc.new{|e| "[VIRAL=#{e}]"}) do
      assert_equal sentence, "Protein ([VIRAL=nsp1]), helicase ([VIRAL=nsp13])."
      Transformed.with_transform(sentence, clean, Proc.new{|e| "[HUMAN=#{e}]"}) do
        assert_equal sentence, "Protein ([VIRAL=nsp1]), [HUMAN=helicase] ([VIRAL=nsp13])."
      end
    end
  end


  def test_collisions2
    text =<<-EOF.chomp
This is another sentence. Among the nonstructural proteins, the leader protein (nsp1), the papain-like protease (nsp3), the nsp4, the 3C-like protease (nsp5), the nsp7, the nsp8, the nsp9, the nsp10, the RNA-directed RNA polymerase (nsp12), the helicase (nsp13), the guanine-N7 methyltransferase (nsp14), the uridylate-specific endoribonuclease (nsp15), the 2'-O-methyltransferase (nsp16), and the ORF7a protein could be built on the basis of homology templates.
    EOF

    sentence_pos = text.index(".") + 2
    sentence = Segment.setup(text[sentence_pos..-1], sentence_pos)

    target = sentence.dup

    viral = %w(nsp1 nsp4 nsp5 nsp7 nsp8 nsp9 nsp10 nsp12 nsp13 nsp14 nsp15 ORF7a spike)
    human = %w(helicase nsp5 nsp4 nsp3)

    viral = viral.collect do |e|
      next unless text.index(e)
      NamedEntity.setup(e, text.index(e), "VirGene")
    end.compact

    human = human.collect do |e|
      next unless text.index(e)
      NamedEntity.setup(e, text.index(e), "HumGene")
    end

    clean = human.reject{|s| s.overlaps(viral).any?}

    tag = Misc.digest("TAG")

    viral.each do |e|
      target.gsub!(/\b#{e}\b/, "[VIRAL=#{e}-#{tag}]")
    end

    target_tmp = target.dup

    clean.each do |e|
      target.gsub!(/\b#{e}\b/, "[HUMAN=#{e}-#{tag}]")
    end

    Transformed.with_transform(sentence, viral, Proc.new{|e| "[VIRAL=#{e}-#{tag}]"}) do
      assert_equal sentence, target_tmp
      Transformed.with_transform(sentence, clean, Proc.new{|e| "[HUMAN=#{e}-#{tag}]"}) do
        assert_equal sentence, target
      end
    end
  end

  def ___test_transform
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

    iii a.transformation_offset_differences
    raise
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

end

