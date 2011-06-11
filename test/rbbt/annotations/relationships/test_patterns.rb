require File.join(File.expand_path(File.dirname(__FILE__)), '../../../test_helper.rb')
require 'rbbt/annotations/relationships/patterns'

class TestPatternRelExt < Test::Unit::TestCase
  def _test_simple_pattern
    text = "Experiments have shown that TP53 interacts with CDK5 under certain conditions"

    gene1 = "TP53"
    NamedEntity.annotate(gene1, text.index(gene1), "Gene")

    gene2 = "CDK5"
    NamedEntity.annotate(gene2, text.index(gene2), "Gene")

    interaction = "interacts"
    NamedEntity.annotate(interaction, text.index(interaction), "Interaction")

    Annotated.annotate(text, [gene1, gene2, interaction])

    assert_equal "TP53 interacts with CDK5", PatternRelExt.new.simple_pattern(text, "GENE INTERACTION with GENE").first

  end

  def test_chunk_pattern
    text = "Experiments have shown that TP53 found in cultivated cells interacts with CDK5 under certain conditions"

    gene1 = "TP53"
    NamedEntity.annotate(gene1, text.index(gene1), "Gene")

    gene2 = "CDK5"
    NamedEntity.annotate(gene2, text.index(gene2), "Gene")

    interaction = "interacts"
    NamedEntity.annotate(interaction, text.index(interaction), "Interaction")

    Annotated.annotate(text, [gene1, gene2, interaction])

    assert_equal "TP53 found in cultivated cells interacts with CDK5", 
      PatternRelExt.new.chunk_patterns([text], "NP[entity:Gene] VP[stem:interacts] with NP[entity:Gene]").first.first


    PatternRelExt.new.chunk_patterns([text], "NP[entity:Gene] VP[entity:Interactor_Cues] with NP[entity:Gene]").first.first
  end
end
