require 'test/unit'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rbbt'
require 'rbbt/util/persistence'
require 'rbbt/util/tmpfile'
require 'rbbt/util/log'
require 'rbbt/corpus/document_repo'

class Test::Unit::TestCase
  def test_datafile(file)
    File.join(File.dirname(__FILE__), 'data', file)
  end

  def setup
    FileUtils.mkdir_p Rbbt.tmp.test.persistence.find(:user)
    Persistence.cachedir = Rbbt.tmp.test.persistence.find :user
  end

  def teardown
    FileUtils.rm_rf Rbbt.tmp.test.find :user
    TCHash::CONNECTIONS.values.each do |c| c.close end
    TCHash::CONNECTIONS.clear
    DocumentRepo::CONNECTIONS.values.each do |c| c.close end
    DocumentRepo::CONNECTIONS.clear
  end

end
