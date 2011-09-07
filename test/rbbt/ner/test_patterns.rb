require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/ner/patterns'

class TestPatternRelExt < Test::Unit::TestCase
  def test_simple_pattern
    text = "Experiments have shown that TP53 interacts with CDK5 under certain conditions"

    gene1 = "TP53"
    NamedEntity.setup(gene1, text.index(gene1), "Gene")

    gene2 = "CDK5"
    NamedEntity.setup(gene2, text.index(gene2), "Gene")

    interaction = "interacts"
    NamedEntity.setup(interaction, text.index(interaction), "Interaction")

    Segmented.setup(text, [gene1, gene2, interaction])

    assert_equal "TP53 interacts with CDK5", PatternRelExt.simple_pattern(text, "GENE INTERACTION with GENE").first
  end

  def test_chunk_pattern
    text = "Experiments have shown that TP53 found in cultivated cells interacts with CDK5 under certain conditions"

    gene1 = "TP53"
    NamedEntity.setup(gene1, text.index(gene1), "Gene")

    gene2 = "CDK5"
    NamedEntity.setup(gene2, text.index(gene2), "Gene")

    interaction = "interacts"
    NamedEntity.setup(interaction, text.index(interaction), "Interaction")

    Segmented.setup(text, {:entities => [gene1, gene2, interaction]})

    assert_equal "TP53 found in cultivated cells interacts with CDK5", 
      PatternRelExt.new("NP[entity:Gene] VP[stem:interacts] with NP[entity:Gene]").match_sentences([text]).first.first

    assert_equal "TP53 found in cultivated cells interacts with CDK5", 
      PatternRelExt.new(["NP[entity:Gene] VP[stem:interacts] with NP[entity:Gene]"]).match_sentences([text]).first.first
  end

  def test_chunk_pattern
    text = "There is a concern with the use of thiazolidinediones in patients with an increased risk of colon cancer (e.g., familial colon polyposis)."

    drug = "thiazolidinediones"
    NamedEntity.setup(drug, text.index(drug), "Chemical Mention")

    disease = "colon cancer"
    NamedEntity.setup(disease, text.index(disease), "disease")

    Segmented.setup(text, {:entitites => [drug, disease]})

    assert_equal "thiazolidinediones in patients with an increased risk of colon cancer", 
      PatternRelExt.new("NP[entity:Chemical Mention] NP[stem:risk] NP[entity:disease]").match_sentences([text]).first.first

  end


  def test_entities_with_spaces
    PatternRelExt.new("NP[entity:Gene Name]").token_trie
  end


end
