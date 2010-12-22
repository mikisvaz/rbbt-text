require File.dirname(__FILE__) + '/../../test_helper'
require 'rbbt-util'
require 'rbbt/ner/regexpNER'
require 'rbbt/sources/polysearch'
require 'test/unit'

class TestRegExpNER < Test::Unit::TestCase
  def test_true
    assert true
  end
  def _test_class
    text = "a bc d e f g h i j k  l m n o p q one two"

    lexicon =<<-EOF
C1,a,x,xx,xxx
C2,bc,y,yy,yyy
C3,i,z,zz,zzz,m,one two
    EOF

    file = TmpFile.tmp_file
    File.open(file, 'w'){|f| f.write lexicon}

    r = RegExpNER.new(file, :sep => ',', :stopwords => false)
    assert_equal(['a', 'bc', 'i', 'm','one two'].sort, r.match_hash(text).values.flatten.sort)

    r = RegExpNER.new(file, :sep => ',', :stopwords => true)
    assert_equal(['bc', 'm','one two'].sort,r.match_hash(text).values.flatten.sort)


    FileUtils.rm file
  end

  def _test_persistence
    text = "a bc d e f g h i j k  l m n o p q one two"

    lexicon =<<-EOF
C1,a,x,xx,xxx
C2,bc,y,yy,yyy
C3,i,z,zz,zzz,m,one two
    EOF

    file = TmpFile.tmp_file
    File.open(file, 'w'){|f| f.write lexicon}

    r = RegExpNER.new(file, :sep => ',', :stopwords => false, :persistence => true)
    assert_equal(['a', 'bc', 'i', 'm','one two'].sort, r.match_hash(text).values.flatten.sort)

    r = RegExpNER.new(file, :sep => ',', :stopwords => true, :persistence => true)
    assert_equal(['bc', 'm','one two'].sort,r.match_hash(text).values.flatten.sort)


    FileUtils.rm file
  end
end

