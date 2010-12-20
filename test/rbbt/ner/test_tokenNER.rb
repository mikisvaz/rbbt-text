require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt-util'
require 'rbbt/ner/tokenNER'
require 'rbbt/ner/named_entity'
require 'test/unit'

class TestTokenNER < Test::Unit::TestCase

  def test_tokenize
    assert_equal ['a' , 'b', ',', 'c'], TokenNER.tokenize('a b, c')
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

      assert_equal ['a', 'b', '1', '2', '3'].sort, index.keys.sort
      assert_equal [:END], index['a'].keys
      assert_equal ['b', :END],  index['b'].keys
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

  def test_polysearch
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
end


