require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/annotations/corpus/document_repo'
require 'rbbt/sources/pubmed'

class TestDocumentRepo < Test::Unit::TestCase
  def test_new
    repo = DocumentRepo.get Rbbt.tmp.test.TCRepo.find :user
    repo.write

    values = ['pubmed', '1111', 'abstract', 'hash1'] 
    key    =  values * ":"

    repo[key] = "Test1"

    repo.read
    assert_equal "Test1", repo[key]
    assert_equal [key], repo.find(*values[0..2])
    assert_equal [key], repo.find(*values[0..1])


    repo = DocumentRepo.get Rbbt.tmp.test.TCRepo.find :user
    repo.write

    values2 = ['pubmed', '1111', 'fulltext', 'hash2'] 
    key2    =  values2 * ":"

    repo[key2] = "Test2"


    repo.read
    assert_equal "Test2", repo[key2]
    assert_equal [key], repo.find(*values[0..2])
    assert_equal [key, key2], repo.find(*values[0..1])
  end
end

