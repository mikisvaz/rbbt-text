require 'rbbt'
require 'rbbt/util/open'

Rbbt.add_datafiles 'stopwords' => ['wordlists', 'stopwords']

$stopwords = Open.read(Rbbt.find_datafile 'stopwords').scan(/\w+/) if File.exists?(Rbbt.find_datafile 'stopwords')

