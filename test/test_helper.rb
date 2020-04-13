require 'test/unit'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rbbt'
require 'rbbt/persist'
require 'rbbt/util/tmpfile'
require 'rbbt/util/log'
require 'rbbt/text/corpus'

class Test::Unit::TestCase
  def get_test_datafile(file)
    File.join(File.dirname(__FILE__), 'data', file)
  end

  def setup
    FileUtils.mkdir_p Rbbt.tmp.test.persistence.find(:user)
    Persist.cachedir = Rbbt.tmp.test.persistence.find :user
  end

  def teardown
    FileUtils.rm_rf Rbbt.tmp.test.find :user
    Persist::CONNECTIONS.values.each do |c| c.close end
    Persist::CONNECTIONS.clear
    Corpus::DocumentRepo::TC_CONNECTIONS.values.each do |c| c.close end
    Corpus::DocumentRepo::TC_CONNECTIONS.clear
  end

end
