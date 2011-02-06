require 'rbbt'
require 'rbbt/util/open'

Rbbt.claim 'stopwords', nil, 'wordlist'

$stopwords = Rbbt.files.wordlists.stopwords.read.scan(/\w+/)

