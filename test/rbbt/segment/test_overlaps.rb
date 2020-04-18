require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/segment'
require 'rbbt/segment/overlaps'

class TestOverlaps < Test::Unit::TestCase
  def setup
    @text = <<-EOF
This is a first sentence. More recently, PPAR activators were shown to inhibit the activation of inflammatory response genes (such as IL-2, IL-6, IL-8, TNF alpha and metalloproteases) by negatively interfering with the NF-kappa B, STAT and AP-1 signalling pathways in cells of the vascular wall.
    EOF

    @entities = ["PPAR", "IL-2", "IL-6", "IL-8", "TNF", "TNF alpha", "NF-kappa B", "AP-1", "STAT"].collect do |literal|
      Segment.setup(literal, :offset => @text.index(literal))
    end
    
    @sentences = @text.partition(".").values_at(0, 2).collect do |sentence|
      Segment.setup sentence, :offset => @text.index(sentence)
    end
  end

  def test_make_relative
    sentence = @sentences[1]

    @entities.each do |e|
      assert_equal e, @text[e.range]
    end

    sentence.make_relative @entities do
      @entities.each do |e|
        assert_equal e, sentence[e.range]
      end

      @entities.each do |e|
        assert_not_equal e, @text[e.range]
      end
    end

    @entities.each do |e|
      assert_equal e, @text[e.range]
    end
  end

  def test_range_in
    sentence = @sentences[1]

    @entities.each do |e|
      assert_equal e.range_in(sentence).begin, sentence.index(e)
      assert_equal e.range.begin - sentence.offset, sentence.index(e)
    end
  end

  def test_includes
    @entities.each do |e|
      assert ! @sentences[0].include?(e)
      assert @sentences[1].include?(e)
      assert ! e.include?(@sentences[0])
      assert ! e.include?(@sentences[1])
    end
  end

  def test_overlaps?
    @entities.each do |e|
      assert ! @sentences[0].overlaps?(e)
      assert @sentences[1].overlaps?(e)
      assert ! e.overlaps?(@sentences[0])
      assert e.overlaps?(@sentences[1])
    end
  end

end
