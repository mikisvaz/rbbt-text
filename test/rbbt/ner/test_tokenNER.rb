require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt-util'
require 'rbbt/ner/tokenNER'
require 'rbbt/ner/named_entity'
require 'test/unit'

class TestTokenNER < Test::Unit::TestCase

  def test_tokenize
    p TokenNER.tokenize('-') 
    assert_equal ['a' , 'b', ',', 'c'], TokenNER.tokenize('a b, c')

    assert_equal (10..14), TokenNER.tokenize('123456789 12345').last.range
    assert_equal (0..8), TokenNER.tokenize('123456789 12345').first.range


    text = '123456789 12345'
    assert_equal '12345', text[TokenNER.tokenize('123456789 12345').last.range]
  end

  def test_tokenize_with_regexp_empty
    assert_equal ['a' , 'b', ',', 'c'], TokenNER.tokenize_with_regexps('a b, c')

    assert_equal (10..14), TokenNER.tokenize_with_regexps('123456789 12345').last.range
    assert_equal (0..8), TokenNER.tokenize_with_regexps('123456789 12345').first.range


    text = '123456789 12345'
    assert_equal '12345', text[TokenNER.tokenize_with_regexps('123456789 12345').last.range]
  end


  def test_merge
    tokens = %w(a b c)
    index = {'a' => {'b' => {'c' => {:END => ['CODE']}}}}

    assert_equal index, TokenNER.merge({}, TokenNER.index_for_tokens(tokens, 'CODE'))
  end

  def test_process
    lexicon =<<-EOF
C1;a;A;b b
C2;1;2;3 3;b
    EOF

    TmpFile.with_file(lexicon) do |file|
      index = TokenNER.process(TSV.new(file, :sep => ';', :flatten => true))

      assert_equal ['A', 'a', 'b', '1', '2', '3'].sort, index.keys.sort
      assert_equal [:END], index['a'].keys
      assert index['b'].keys.include? 'b'
      assert index['b'].keys.include? :END
    end
  end

  def test_find
    lexicon =<<-EOF
C1;a;A;b b
C2;1;2;3 3;b
    EOF


    TmpFile.with_file(lexicon) do |file|
      index = TokenNER.process(TSV.new(file, :sep => ';', :flatten => true))

      assert TokenNER.find(index, TokenNER.tokenize('a asdf'), false).first.include?   'C1'
      assert_equal %w(a), TokenNER.find(index, TokenNER.tokenize('a asdf'), false).last

      assert TokenNER.find(index, TokenNER.tokenize('a asdf'), true).first.include?    'C1'

      assert TokenNER.find(index, TokenNER.tokenize('b b asdf'), true).first.include?  'C1'
      assert_equal %w(b b), TokenNER.find(index, TokenNER.tokenize('b b asdf'), true).last

      assert TokenNER.find(index, TokenNER.tokenize('b b asdf'), false).first.include? 'C2'
      assert_equal %w(b), TokenNER.find(index, TokenNER.tokenize('b b asdf'), false).last

      assert TokenNER.find(index, TokenNER.tokenize('b asdf'), false).first.include?   'C2'
    end
  end

  def test_extract
    lexicon =<<-EOF
C1;a;A;b b
C2;1;2;3 3;b
    EOF

    TmpFile.with_file(lexicon) do |file|
      index = TokenNER.new(file, :sep => ';')

      assert index.extract(' asdfa dsf asdf a asdfasdf ').include? 'C1'
    end

  end

  def test_polysearch_long_match
    begin
      require 'rbbt/sources/polysearch'
    rescue
      puts "Polysearch is not available. Some test have not ran."
      assert true
      return
    end

    sentence = "mammary and pituitary neoplasms as well as other drug-related mammary/reproductive tissue alterations in females were considered"

    index = TokenNER.new Rbbt.find_datafile('organ')
    assert index.extract(sentence).include? 'OR00063'

    index = TokenNER.new Rbbt.find_datafile('disease')
    assert index.extract(sentence).include? 'DID44386'

    index = TokenNER.new Rbbt.find_datafile('disease'), Rbbt.find_datafile('organ')
    assert index.extract(sentence).include? 'DID44386'

    index = TokenNER.new Rbbt.find_datafile('disease'), Rbbt.find_datafile('organ')
    assert index.extract(sentence).include? 'DID44386'

    index = TokenNER.new Rbbt.find_datafile('organ')
    assert index.extract(sentence).include? 'OR00063'
    index.merge Rbbt.find_datafile('disease')
    assert ! index.extract(sentence).include?('OR00063')
    assert index.extract(sentence).include? 'DID44386'
  end


  def __test_polysearch
    begin
      require 'rbbt/sources/polysearch'
    rescue
      puts "Polysearch is not available. Some test have not ran."
      assert true
      return
    end

    sentence = "The incidence of influenza complications (otitis media, sinusitis, lower respiratory tract infection, bronchitis, or pneumonia) was significantly lower in the oseltamivir group than in the placebo group (0.4% versus 2.6%, p=0.037)."

    index = TokenNER.new Rbbt.find_datafile('organ')
    assert index.extract(sentence).include? 'OR00068'

    index = TokenNER.new Rbbt.find_datafile('disease')
    assert index.extract(sentence).include? 'DID44183'

    index = TokenNER.new Rbbt.find_datafile('disease'), Rbbt.find_datafile('organ')
    assert index.extract(sentence).include? 'DID44183'

    index = TokenNER.new Rbbt.find_datafile('disease'), Rbbt.find_datafile('organ')
    assert index.extract(sentence).include? 'DID44183'

    index = TokenNER.new Rbbt.find_datafile('organ')
    assert index.extract(sentence).include? 'OR00068'
    index.merge Rbbt.find_datafile('disease')
    assert ! index.extract(sentence).include?('OR00068')
    assert index.extract(sentence).include? 'DID44183'
  end

  def test_match_regexp
    sentence = "The incidence of influenza complications (otitis media, sinusitis, lower respiratory tract infection, bronchitis, or pneumonia) was significantly lower in the oseltamivir group than in the placebo group (0.4% versus 2.6%, p=0.037)."

    matches, chunks = TokenNER.match_regexp(sentence, /[\d\.]+\%/)

    assert matches.include? '0.4%'
    assert_equal 3, chunks.length

    chunks.each do |chunk, start|
      assert_equal(sentence[start..(start + chunk.length - 1)], chunk)
    end
  end

  def test_match_regexps
    sentence = "The incidence of influenza complications (otitis media, sinusitis, lower respiratory tract infection, bronchitis, or pneumonia) was significantly lower in the oseltamivir group than in the placebo group (0.4% versus 2.6%, p=0.037)."

    matches, chunks = TokenNER.match_regexps(sentence, [[/[\d\.]+\%/, "percentage"], [/0.[\d]+/, "pvalue"]])

    assert matches.include? '0.4%'
    assert matches.select{|m| m == '0.4%'}.first.type == "percentage"

    chunks.each do |chunk, start|
      assert_equal(sentence[start..(start + chunk.length - 1)], chunk)
    end
  end


  def test_regexp
    lexicon =<<-EOF
C1;sinusitis
C2;FOO
    EOF


    sentence = "The incidence of influenza complications (otitis media, sinusitis, lower respiratory tract infection, bronchitis, or pneumonia) was significantly lower in the oseltamivir group than in the placebo group (0.4% versus 2.6%, p=0.037)."

    TmpFile.with_file(lexicon) do |file|
      index = TokenNER.new file,  :sep => ';'
      assert index.extract(sentence).include? 'C1'

      index.add_regexp /[\d\.]+\%/ => "percentage"

      assert index.extract(sentence).include? 'percentage'
      assert index.extract(sentence)["percentage"].include? '0.4%'
    end

    TmpFile.with_file(lexicon) do |file|
      index = TokenNER.new file,  :sep => ';'
      assert index.extract(sentence).include? 'C1'

      index.define_regexp do
        percentage /[\d\.]+\%/
      end

      assert index.extract(sentence).include? 'percentage'
      assert index.extract(sentence)["percentage"].include? '0.4%'
    end
  end

  def test_regexp_captures
    lexicon =<<-EOF
C1;sinusitis
C2;FOO
    EOF


    sentence = "The incidence of influenza complications (otitis media, sinusitis, lower respiratory tract infection, bronchitis, or pneumonia) was significantly lower in the oseltamivir group than in the placebo group (0.4% versus 2.6%, p=0.037)."

    TmpFile.with_file(lexicon) do |file|
      index = TokenNER.new file,  :sep => ';'
      assert index.extract(sentence).include? 'C1'

      index.define_regexp do
        percentage /([\d\.]+)\%/
      end

      assert index.extract(sentence).include? 'percentage'
      assert index.extract(sentence)["percentage"].include? '0.4'
    end
  end

end


