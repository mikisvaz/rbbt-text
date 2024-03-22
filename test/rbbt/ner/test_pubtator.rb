require File.expand_path(__FILE__).sub(%r(/test/.*), '/test/test_helper.rb')
require File.expand_path(__FILE__).sub(%r(.*/test/), '').sub(/test_(.*)\.rb/,'\1')

require 'rbbt/ner/NER'
require 'rbbt/document'
require 'rbbt/document/corpus'
require 'rbbt/document/corpus/pubmed'
class TestPubtator < Test::Unit::TestCase
  def with_corpus(&block)
    TmpFile.with_file do |corpus|
      yield Document::Corpus.setup(corpus)
    end
  end

  def test_align
    pmids = "19522013|20861254|38267746".split("|")
    alignments = {} 
    with_corpus do |corpus|
      corpus.add_pmid(pmids).each do |document|
        alignments[document.code] = document
      end
      entities = Pubtator.pubtator_entities(pmids, ['gene'], alignments)
      entities.each do |pmid,list|
        document = corpus.add_pmid(pmid)
        list.each do |entity|
          assert_equal entity, document[entity.range]
        end
      end
    end
  end

  def test_pmid
    Log.severity = 0
    pmids = "22291955".split("|")
    alignments = {} 
    with_corpus do |corpus|
      corpus.add_pmid(pmids).each do |document|
        alignments[document.code] = document
      end
      entities = Pubtator.pubtator_entities(pmids, ['gene'], alignments)
      entities.each do |pmid,list|
        document = corpus.add_pmid(pmid)
        list.each do |entity|
          assert_equal entity, document[entity.range]
        end
      end
    end
  end

  def test_greek

    pmids = "20861254".split("|")
    alignments = {} 
    with_corpus do |corpus|
      corpus.add_pmid(pmids).each do |document|
        alignments[document.code] = document
      end
      entities = Pubtator.pubtator_entities(pmids, ['gene'], alignments)
      entities.each do |pmid,list|
        document = corpus.add_pmid(pmid)
        list.each do |entity|
          assert_equal entity, document[entity.range]
        end
        assert list.select{|e| e.include? 'α' }.any?
      end

    end
  end
end

