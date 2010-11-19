require 'rbbt/util/open'
$stopwords = Open.read(File.join(Rbbt.datadir, 'wordlists/stopwords')).scan(/\w+/) if File.exists? File.join(Rbbt.datadir, 'wordlists/stopwords')
