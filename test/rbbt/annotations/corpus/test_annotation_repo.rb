require File.join(File.expand_path(File.dirname(__FILE__)), '../../../test_helper.rb')
require 'rbbt/annotations/corpus'
require 'rbbt/annotations/corpus/annotation_repo'
require 'rbbt/annotations/corpus/pubmed'

class TestAnnotationRepo < Test::Unit::TestCase

  @@text=<<-EOF
Atypical teratoid/rhabdoid tumors (AT/RTs) are highly aggressive brain tumors
of early childhood poorly responding to therapy. The majority of cases show
inactivation of SMARCB1 (INI1, hSNF5, BAF47), a core member of the adenosine
triphosphate (ATP)-dependent SWI/SNF chromatin-remodeling complex. We here
report the case of a supratentorial AT/RT in a 9-month-old boy, which showed
retained SMARCB1 staining on immunohistochemistry and lacked genetic
alterations of SMARCB1. Instead, the tumor showed loss of protein expression of
another SWI/SNF chromatin-remodeling complex member, the ATPase subunit SMARCA4
(BRG1) due to a homozygous SMARCA4 mutation [c.2032C>T (p.Q678X)].  Our
findings highlight the role of SMARCA4 in the pathogenesis of SMARCB1-positive
AT/RT and the usefulness of antibodies directed against SMARCA4 in this
diagnostic setting.
  EOF

  @@comment = "Some string of text"

  @@docid = Misc.digest(@@text) 

  def test_repo
    repo = AnnotationRepo.new Rbbt.tmp.test.annotation_repo.find
    sentences = NLP.geniass_sentence_splitter(@@text)

    repo.write
    sentences.each do |s|
      s.docid = @@docid
      repo.add_segment(@@docid, "Sentences", s)
    end
    #- Add different type of segment: a comment
    repo.add_segment(@@docid, "Source", Comment.annotate(@@comment))

    repo.read

    assert_equal @@comment, repo.segments_for(@@text, @@docid).select{|s| s.respond_to? :comment}.first.comment

    assert repo.segments_for(@@text, @@docid).select{|s|
      s.respond_to? :comment
    }.any?

    assert repo.segments_at(@@text, @@docid, 100, "Sentences").select{|s|
      s.docid != @@docid
    }.empty?

    assert repo.segments_at(@@text, @@docid, 100, "Sentences").select{|s|
      s =~ /Atypical/
    }.any?
  end

  def test_filter
    repo = AnnotationRepo.new Rbbt.tmp.test.annotation_repo
    sentences = NLP.geniass_sentence_splitter(@@text)

    repo.write
    sentences.each do |s|
      s.docid = @@docid
      repo.add_segment(@@docid, "Sentences", s)
    end
    #- add different type of segment: a comment
    repo.add_segment(@@docid, "Source", Comment.annotate(@@comment))

    #- basic
    assert 1, repo.find_annotation_ids(nil, "Source")
  end
end
