require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt/ner/regexpNER'

class TestRegExpNER < Test::Unit::TestCase
  def test_match_regexp
    sentence = "In this sentence I should find this and 'that'"

    regexp = /this/
    matches = RegExpNER.match_regexp(sentence, regexp)

    assert_equal ["this", "this"], matches
    assert_equal "In ".length, matches[0].offset
    assert_equal "In this sentence I should find ".length, matches[1].offset

    regexp_list = [/this/, /that/]
    matches = RegExpNER.match_regexp_list(sentence, regexp_list)

    assert_equal ["this", "this", "that"], matches
    assert_equal "In ".length, matches[0].offset
    assert_equal "In this sentence I should find ".length, matches[1].offset

    regexp_hash = {:this => /this/, :that => /that/}
    matches = RegExpNER.match_regexp_hash(sentence, regexp_hash)

    assert_equal ["this", "this", "that"].sort, matches.sort
    assert_equal "In ".length, matches.select{|m| m.type == :this}[0].offset
    assert_equal "In this sentence I should find ".length, matches.select{|m| m.type == :this}[1].offset
    assert_equal :this, matches.select{|m| m.type == :this}[0].type
  end

  def test_define_regexps
    sentence = "In this sentence I should find this and 'that'"

    ner = RegExpNER.new
    ner.define_regexp do
      this /this/
      that /that/
    end

    matches = ner.entities(sentence)
    assert_equal ["this", "this", "that"].sort, matches.sort
    assert_equal "In ".length, matches.select{|m| m.type == :this }[0].offset
    assert_equal "In this sentence I should find ".length, matches.select{|m| m.type == :this }[1].offset
    assert_equal :this, matches.select{|m| m.type == :this }[0].type
  end


  def test_entities
    sentence = "In this sentence I should find this and 'that'"

    ner = RegExpNER.new({:this => /this/, :that => /that/})
    matches = ner.entities(sentence)
    assert_equal ["this", "this", "that"].sort, matches.sort
    assert_equal "In ".length, matches.select{|m| m.type == :this}[0].offset
    assert_equal "In this sentence I should find ".length, matches.select{|m| m.type == :this}[1].offset
    assert_equal :this, matches.select{|m| m.type == :this}[0].type

    Annotated.annotate(sentence)
    ner_this = RegExpNER.new({:this => /this/})
    ner_that = RegExpNER.new({:that => /that/})
    sentence.annotations += ner_this.entities(sentence)
    sentence.annotations += ner_that.entities(sentence)
    matches = sentence.annotations

    assert_equal ["this", "this", "that"].sort, matches.sort
    assert_equal "In ".length, matches.select{|m| m.type == :this}[0].offset
    assert_equal "In this sentence I should find ".length, matches.select{|m| m.type == :this}[1].offset
    assert_equal :this, matches.select{|m| m.type == :this}[0].type
  end

  def test_entities_captures
    sentence = "In this sentence I should find this and 'that'"

    ner = RegExpNER.new({:this => /this/, :that => /that/, :should => /I (should)/})
    matches = ner.entities(sentence)
    assert_equal ["this", "this", "that", "should"].sort, matches.sort
    assert_equal "In this sentence I ".length, matches.select{|m| m.type == :should}[0].offset
    assert_equal :should, matches.select{|m| m.type == :should}[0].type
  end

  def test_regexp_order
    text =<<-EOF
  * Human AUC 0-24h= 7591 ng.h/ml at 30 mg/day    In mice, dietary administration of aripiprazole at doses of 1, 3, and 10 asdf mg/kg/day for 104 weeks was
  associated with increased incidences of mammary tumors, namely adenocarcinomas
    EOF



    regexp = RegExpNER.new
    regexp.define_regexp do
      dosage           /\d+\s*(?:[mnukg]{1,2}|mol)(?:\/[mnguk]{1,2})?(?:\/day|d|hour|h|minute|min|m)?/i
      time             /[\d\.]+\s+(?:minute|hour|day|week|mounth|year)s?/i
    end

    offsets = {
      "7591 ng" => 21,
      "30 mg/day" => 37,
      "104 weeks" => 142,
    }
    regexp.match(text).each do |entity|
      assert_equal offsets[entity], entity.offset
    end
  end
end
