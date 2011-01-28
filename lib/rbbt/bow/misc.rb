require 'rbbt'
require 'rbbt/util/open'

Rbbt.claim 'stopwords', 'stopwords', 'wordlist'

$stopwords = Rbbt.files.wordlists.stopwords.read.scan(/\w+/)

