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
    tokens.extend TokenTrieNER::EnumeratedArray
    index = {'a' => {'b' => {'c' => {:END => [TokenTrieNER::Code.new('CODE')]}}}}

    assert_equal 'CODE', TokenTrieNER.merge({}, TokenTrieNER.index_for_tokens(tokens, 'CODE'))['a']['b']['c'][:END].first.code
  end

  def test_process
    lexicon =<<-EOF
C1;aa;AA;bb b
C2;11;22;3 3;bb
    EOF

    TmpFile.with_file(lexicon) do |file|

      index = TokenTrieNER.process({}, TSV.open(file, :flat, :sep => ';'))

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
      index = TokenTrieNER.process({}, TSV.open(file, :sep => ';', :type => :flat ))

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('aa asdf').extend(TokenTrieNER::EnumeratedArray), false).first.collect{|c| c.code}.include?   'C1'
      assert_equal %w(aa), TokenTrieNER.find(index, TokenTrieNER.tokenize('aa asdf').extend(TokenTrieNER::EnumeratedArray), false).last

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('aa asdf').extend(TokenTrieNER::EnumeratedArray), true).first.collect{|c| c.code}.include?    'C1'

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('bb b asdf').extend(TokenTrieNER::EnumeratedArray), true).first.collect{|c| c.code}.include?  'C1'
      assert_equal %w(bb b), TokenTrieNER.find(index, TokenTrieNER.tokenize('bb b asdf').extend(TokenTrieNER::EnumeratedArray), true).last

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('bb b asdf').extend(TokenTrieNER::EnumeratedArray), false).first.collect{|c| c.code}.include? 'C2'
      assert_equal %w(bb), TokenTrieNER.find(index, TokenTrieNER.tokenize('bb b asdf').extend(TokenTrieNER::EnumeratedArray), false).last

      assert TokenTrieNER.find(index, TokenTrieNER.tokenize('bb asdf').extend(TokenTrieNER::EnumeratedArray), false).first.collect{|c| c.code}.include? 'C2'
    end
  end

  def test_match
    lexicon =<<-EOF
C1;aa;AA;bb b
C2;11;22;3 3;bb
    EOF

    TmpFile.with_file(lexicon) do |file|
      index = TokenTrieNER.new("test", TSV.open(file, :flat, :sep => ';'))

      assert index.match(' asdfa dsf asdf aa asdfasdf ').select{|m| m.code.include? 'C1'}.any?
    end
  end

  def test_slack
    lexicon =<<-EOF
C1;aa;AA;bb cc cc b
C2;11;22;3 3;bb;bbbb
    EOF

    TmpFile.with_file(lexicon) do |file|
      index = TokenTrieNER.new({})
      index.slack = Proc.new{|t| t =~ /^c*$/}

      index.merge TSV.open(file, :flat, :sep => ';')

      assert index.match(' aaaaa 3 cc 3').select{|m| m.code.include? 'C2'}.any?
      assert index.match(' bb cc b').select{|m| m.code.include? 'C1'}.any?
      assert index.match(' bb b').select{|m| m.code.include? 'C1'}.any?
      assert index.match(' BBBB b').select{|m| m.code.include? 'C2'}.any?
    end
  end

  def test_own_tokens
    lexicon =<<-EOF
C1;aa;AA;bb cc cc b
C2;11;22;3 3;bb
    EOF

    TmpFile.with_file(lexicon) do |file|
      index = TokenTrieNER.new({})
      index.slack = Proc.new{|t| t =~ /^c*$/}

      index.merge TSV.open(file, :flat, :sep => ';')

      assert index.match(Token.tokenize('3 cc 3')).select{|m| m.code.include? 'C2'}.any?
    end
  end

  def test_proc_index
    index = TokenTrieNER.new({})
    index.merge({ "aa" => {:PROCS => {Proc.new{|c| c == 'c'} => {:END  => [TokenTrieNER::Code.new(:entity, :C1)]}}}})

    assert index.match(Token.tokenize('3 cc 3 aa c ddd')).select{|m| m.code.include? :entity}.any?
  end

  def test_persistence
    lexicon =<<-EOF
C1;aa;AA;bb b
C2;11;22;3 3;bb
    EOF

    TmpFile.with_file(lexicon) do |file|
      index = TokenTrieNER.new("test", TSV.open(file, :flat, :sep => ';'), :persistence => true)

      assert index.match(' asdfa dsf asdf aa asdfasdf ').select{|m| m.code.include? 'C1'}.any?
    end
  end

end

