require 'rbbt-util'
require 'rbbt/entity'

require 'rbbt/text/corpus'

module Document
  extend Entity
  class << self
    attr_accessor :corpus
  end

  property :document => :single do
    Document.corpus.docid(self)
  end

  property :type => :single do |type|
    self.annotate((self.split(":").values_at(0,1)) * ":" + ":" + type.to_s)
  end

  property :title => :single do
    type(:title).text
  end

  property :full_text => :single do
    type(:full_text).text
  end

  property :abstract => :single do
    type(:abstract).text
  end

  property :text => :single do
    document.text
  end

  property :entities => :single do |type,*args|
    document.method(type).call *args
  end
end
