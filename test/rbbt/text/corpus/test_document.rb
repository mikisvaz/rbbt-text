require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/text/corpus/document'

class TestCorpusDocument < Test::Unit::TestCase
  def setup
    Log.severity = 0

    Corpus::Document.define :words do
      words = self.text.split(" ")
      Segment.align(self.text, words)
    end

    Corpus::Document.define_multiple :words2 do |documents|
      documents.collect do |doc|
        words = doc.text.split(" ")
        Segment.align(doc.text, words)
      end
    end

    Open.mkdir Rbbt.tmp.test.annotations.find

    Corpus::Document.persist_in_global_tsv(:words, Rbbt.tmp.test.anotations.words.find)
    Corpus::Document.persist_in_global_tsv(:words2, Rbbt.tmp.test.anotations.counts.find)
  end

  def test_words
    text = "This is a test document"
    document = Corpus::Document.new(Rbbt.tmp.test.persist, "TEST:test_doc:1", text)
    assert_equal Segment.sort(document.words), text.split(" ")
    assert document.words.first.docid
    assert document.words.first.segment_id.include?("TEST")
  end

  def test_words_multiple
    document1 = Corpus::Document.new(Rbbt.tmp.test.persist, "TEST:test_doc:1", "This is a test document")
    document2 = Corpus::Document.new(Rbbt.tmp.test.persist, "TEST:test_doc2:2", "This is another test document")
    document3 = Corpus::Document.new(Rbbt.tmp.test.persist, "TEST:test_doc3:3", "This is yet another test document")

    docs = [document1, document2, document3]

    Corpus::Document.prepare_multiple(docs, :words2)

    assert document1.words.first.docid
    assert document1.words.first.segment_id.include?("TEST")

    assert_equal document1.words2, document1.text.split(" ")
    assert_equal document2.words2, document2.text.split(" ")
    assert_equal document3.words2, document3.text.split(" ")

    document1 = Corpus::Document.new(Rbbt.tmp.test.persist, "TEST:test_doc:1", "This is a test document")
    document2 = Corpus::Document.new(Rbbt.tmp.test.persist, "TEST:test_doc2:2", "This is another test document")

    docs = [document1, document2]

    Corpus::Document.prepare_multiple(docs, :words2)
  end

  def test_parallel
    text =<<-EOF
This is a test document number
    EOF

    docs = []
    100.times do |i|
      docs << text.chomp + " " + i.to_s
    end

    Log.with_severity 0 do
      TSV.traverse docs, :cpus => 10, :bar => true do |doc|
        hash = Misc.digest(doc)
        document = Corpus::Document.new(Rbbt.tmp.test.persist, "TEST:test_doc:test:#{hash}", doc)
        assert_equal Segment.sort(document.words), document.text.split(" ")
      end
      TSV.traverse docs, :cpus => 10, :bar => true do |doc|
        hash = Misc.digest(doc)
        document = Corpus::Document.new(Rbbt.tmp.test.persist, "TEST:test_doc:test:#{hash}", doc)
        assert_equal Segment.sort(document.words), document.text.split(" ")
      end
    end
  end
end

