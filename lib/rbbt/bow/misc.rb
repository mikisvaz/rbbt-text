require 'rbbt'
require 'rbbt/util/open'

Rbbt.claim 'stopwords', nil, 'wordlists'

$stopwords = Rbbt.files.wordlists.stopwords.read.scan(/\w+/)

