require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/token_trieNER'
require 'rbbt/util/tmpfile'

class TestTokenTrieNER < Test::Unit::TestCase

  def test_tokenize
    assert_equal ['a' , 'b', ',', 'c'], TokenTrieNER.tokenize('a b, c')

    assert_equal 10, TokenTrieNER.tokenize('123456789 12345').last.offset
    assert_equal 0, TokenTrieNER.tokenize('123456789 12345').first.offset


    text = '123456789 12345'
    assert_equal '12345', text[TokenTrieNER.tokenize('123456789 12345').last.range]
  end

  def test_merge
    tokens = %w(a b c)
    index = {'a' => {'b' => {'c' => {:END => [TokenTrieNER::Code.new 'CODE']}}}}

    assert_equal 'CODE', TokenTrieNER.merge({}, TokenTrieNER.index_for_tokens(tokens, 'CODE'))['a']['b']['c'][:END].first.value
  end

  def test_process
    lexicon =<<-EOF
C1;aa;AA;bb b
C2;11;22;3 3;bb
    EOF

    TmpFile.with_file(lexicon) do |file|

      index = TokenTrieNER.process(TSV.new(file, :sep => ';', :flatten => true))

      assert_equal ['AA', 'aa', 'bb', '11', '22', '3'].sort, index.keys.sort
      assert_equal [:END], index['aa'].keys
      assert index['bb'].keys.include? 'b'
      assert index['bb'].keys.include? :END
    end
  end

  def test_find
    lexicon =<<-EOF
C1;aa;AA;bb b
C2;11;22;3 3;bb
    EOF


    TmpFile.with_file(lexicon) do |file|
      index = TokenTrieNER.process(TSV.new(file, :sep => ';', :flatten => true))

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('aa asdf'), false).first.collect{|c| c.value}.include?   'C1'
      assert_equal %w(aa), TokenTrieNER.find(index, TokenTrieNER.tokenize('aa asdf'), false).last

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('aa asdf'), true).first.collect{|c| c.value}.include?    'C1'

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('bb b asdf'), true).first.collect{|c| c.value}.include?  'C1'
      assert_equal %w(bb b), TokenTrieNER.find(index, TokenTrieNER.tokenize('bb b asdf'), true).last

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('bb b asdf'), false).first.collect{|c| c.value}.include? 'C2'
      assert_equal %w(bb), TokenTrieNER.find(index, TokenTrieNER.tokenize('bb b asdf'), false).last

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('bb asdf'), false).first.collect{|c| c.value}.include?   'C2'
    end
  end

  def test_match
    lexicon =<<-EOF
C1;aa;AA;bb b
C2;11;22;3 3;bb
    EOF

    TmpFile.with_file(lexicon) do |file|
      index = TokenTrieNER.new(file, nil, :sep => ';')

      assert index.match(' asdfa dsf asdf aa asdfasdf ').select{|m| m.code.include? 'C1'}.any?
    end
  end

  def _test_polysearch_long_match
    begin
      require 'rbbt/sources/polysearch'
    rescue
      puts "Polysearch is not available. Some test have not ran."
      assert true
      return
    end

    sentence = "mammary and pituitary neoplasms as well as other drug-related mammary/reproductive tissue alterations in females were considered"

    index = TokenTrieNER.new Rbbt.find_datafile('organ')
    assert index.match(sentence).collect{|m| m.code}.flatten.include? 'OR00063'

    index = TokenTrieNER.new Rbbt.find_datafile('disease')
    assert index.match(sentence).collect{|m| m.code}.flatten.include? 'DID44386'

    index = TokenTrieNER.new Rbbt.find_datafile('disease'), Rbbt.find_datafile('organ')
    assert index.match(sentence).collect{|m| m.code}.flatten.include? 'DID44386'

    index = TokenTrieNER.new Rbbt.find_datafile('disease'), Rbbt.find_datafile('organ')
    assert index.match(sentence).collect{|m| m.code}.flatten.include? 'DID44386'

    index = TokenTrieNER.new Rbbt.find_datafile('organ')
    assert index.match(sentence).collect{|m| m.code}.flatten.include? 'OR00063'
    index.merge Rbbt.find_datafile('disease')
    assert ! index.match(sentence).collect{|m| m.code}.flatten.include?('OR00063')
    assert index.match(sentence).collect{|m| m.code}.flatten.include? 'DID44386'
  end


end

