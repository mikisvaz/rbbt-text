require File.join(File.expand_path(File.dirname(__FILE__)), '../../test_helper.rb')
require 'rbbt/corpus/corpus'
require 'rbbt/corpus/sources/pubmed'

class Document
  define :sentences do 
    require 'rbbt/nlp/nlp'
    NLP.geniass_sentence_splitter(text)
  end

  define :genes do 
    require 'rbbt/ner/abner'
    Abner.new.entities(text)
  end
end

 
class TestCorpus < Test::Unit::TestCase

  def test_add_document
    pmid = "19458159"

    text = PubMed.get_article(pmid).text

    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)

    assert corpus.find(:pubmed, pmid).empty?

    corpus.add_document(text, :pubmed, pmid, :abstract)

    assert corpus.find(:pubmed, pmid).any?
    assert corpus.find(:pubmed, pmid, :fulltext).empty?
    assert corpus.find(:pubmed, pmid, :abstract).any?

    assert corpus.find(:pubmed, pmid).first.text =~ /SENT/
  end

  def test_add_pmid
    pmid = "19465387"
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid(pmid, :abstract)

    assert corpus.exists? :pubmed, pmid
    assert corpus.exists? :pubmed, pmid, :abstract
    assert_equal false, corpus.exists?(:pubmed, pmid, :fulltext) 
  end

  def test_find_all
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid("19458159", :abstract)
    corpus.add_pmid("19465387", :abstract)

    all = corpus.find

    assert_equal 2, all.length
    assert all.select{|document| document.id == "19458159"}.any?
    assert all.select{|document| document.id == "19465387"}.any?
  end

  def test_doc_sentences
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid("19458159", :abstract)

    sentences = corpus.find.collect{|doc| doc.sentences}.flatten

    assert corpus.find.first.sentences.length > 0 
    assert corpus.find.first.sentences.sort_by{|s| s.offset}.first =~ /Semantic features in Text/i

    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    assert corpus.find.first.sentences.sort_by{|s| s.offset}.first =~ /Semantic features in Text/i
  end

  def test_doc_genes
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid("21611789", :abstract)
    
    assert corpus.find(:pubmed, "21611789").first.genes.include? "CDKAL1"
  end

  def test_genes
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid("21611789", :abstract)

    assert corpus.find.collect{|d| d.genes}.flatten.include? "CDKAL1"
  end

  def test_index
    corpus = Corpus.new(Rbbt.tmp.test.Corpus.find :user)
    corpus.add_pmid("21611789", :abstract)

    document = corpus.find(:pubmed, "21611789").first

    genes = corpus.find.collect{|d| d.genes}.flatten.select{|gene| gene == "CDKAL1"}

    assert genes.collect{|gene|
      document.sentences_at(gene.offset)
    }.flatten.length >  1
  end
end
