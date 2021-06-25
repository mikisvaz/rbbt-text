# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: rbbt-text 1.3.6 ruby lib

Gem::Specification.new do |s|
  s.name = "rbbt-text".freeze
  s.version = "1.3.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Miguel Vazquez".freeze]
  s.date = "2021-06-25"
  s.description = "Text mining tools: named entity recognition and normalization, document classification, bag-of-words, dictionaries, etc".freeze
  s.email = "miguel.vazquez@fdi.ucm.es".freeze
  s.executables = ["get_ppis.rb".freeze]
  s.files = [
    "lib/rbbt/bow/bow.rb",
    "lib/rbbt/bow/dictionary.rb",
    "lib/rbbt/bow/misc.rb",
    "lib/rbbt/document.rb",
    "lib/rbbt/document/annotation.rb",
    "lib/rbbt/document/corpus.rb",
    "lib/rbbt/document/corpus/pubmed.rb",
    "lib/rbbt/ner/NER.rb",
    "lib/rbbt/ner/abner.rb",
    "lib/rbbt/ner/banner.rb",
    "lib/rbbt/ner/brat.rb",
    "lib/rbbt/ner/chemical_tagger.rb",
    "lib/rbbt/ner/finder.rb",
    "lib/rbbt/ner/g_norm_plus.rb",
    "lib/rbbt/ner/linnaeus.rb",
    "lib/rbbt/ner/ngram_prefix_dictionary.rb",
    "lib/rbbt/ner/oscar3.rb",
    "lib/rbbt/ner/oscar4.rb",
    "lib/rbbt/ner/patterns.rb",
    "lib/rbbt/ner/regexpNER.rb",
    "lib/rbbt/ner/rner.rb",
    "lib/rbbt/ner/rnorm.rb",
    "lib/rbbt/ner/rnorm/cue_index.rb",
    "lib/rbbt/ner/rnorm/tokens.rb",
    "lib/rbbt/ner/token_trieNER.rb",
    "lib/rbbt/nlp/genia/sentence_splitter.rb",
    "lib/rbbt/nlp/nlp.rb",
    "lib/rbbt/nlp/open_nlp/sentence_splitter.rb",
    "lib/rbbt/nlp/spaCy.rb",
    "lib/rbbt/relationship.rb",
    "lib/rbbt/segment.rb",
    "lib/rbbt/segment/annotation.rb",
    "lib/rbbt/segment/encoding.rb",
    "lib/rbbt/segment/named_entity.rb",
    "lib/rbbt/segment/overlaps.rb",
    "lib/rbbt/segment/range_index.rb",
    "lib/rbbt/segment/relationship.rb",
    "lib/rbbt/segment/segmented.rb",
    "lib/rbbt/segment/token.rb",
    "lib/rbbt/segment/transformed.rb",
    "lib/rbbt/segment/tsv.rb",
    "share/install/software/ABNER",
    "share/install/software/BANNER",
    "share/install/software/ChemicalTagger",
    "share/install/software/GNormPlus",
    "share/install/software/Gdep",
    "share/install/software/Geniass",
    "share/install/software/Linnaeus",
    "share/install/software/OSCAR3",
    "share/install/software/OSCAR4",
    "share/install/software/OpenNLP",
    "share/install/software/StanfordParser",
    "share/patterns/drug_induce_disease",
    "share/rner/config.rb",
    "share/rnorm/cue_default",
    "share/rnorm/tokens_default",
    "share/wordlists/stopwords"
  ]
  s.homepage = "http://github.com/mikisvaz/rbbt-util".freeze
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Text mining tools for the Ruby Bioinformatics Toolkit (rbbt)".freeze
  s.test_files = ["test/rbbt/nlp/test_nlp.rb".freeze, "test/rbbt/nlp/open_nlp/test_sentence_splitter.rb".freeze, "test/rbbt/nlp/genia/test_sentence_splitter.rb".freeze, "test/rbbt/bow/test_bow.rb".freeze, "test/rbbt/bow/test_misc.rb".freeze, "test/rbbt/bow/test_dictionary.rb".freeze, "test/rbbt/test_document.rb".freeze, "test/rbbt/document/test_annotation.rb".freeze, "test/rbbt/document/corpus/test_pubmed.rb".freeze, "test/rbbt/document/test_corpus.rb".freeze, "test/rbbt/entity/test_document.rb".freeze, "test/rbbt/ner/test_patterns.rb".freeze, "test/rbbt/ner/test_NER.rb".freeze, "test/rbbt/ner/test_abner.rb".freeze, "test/rbbt/ner/test_rnorm.rb".freeze, "test/rbbt/ner/test_regexpNER.rb".freeze, "test/rbbt/ner/test_ngram_prefix_dictionary.rb".freeze, "test/rbbt/ner/test_brat.rb".freeze, "test/rbbt/ner/test_g_norm_plus.rb".freeze, "test/rbbt/ner/test_chemical_tagger.rb".freeze, "test/rbbt/ner/test_banner.rb".freeze, "test/rbbt/ner/test_token_trieNER.rb".freeze, "test/rbbt/ner/test_finder.rb".freeze, "test/rbbt/ner/test_rner.rb".freeze, "test/rbbt/ner/test_linnaeus.rb".freeze, "test/rbbt/ner/test_oscar4.rb".freeze, "test/rbbt/test_segment.rb".freeze, "test/rbbt/segment/test_transformed.rb".freeze, "test/rbbt/segment/test_overlaps.rb".freeze, "test/rbbt/segment/test_annotation.rb".freeze, "test/rbbt/segment/test_named_entity.rb".freeze, "test/rbbt/segment/test_encoding.rb".freeze, "test/rbbt/segment/test_range_index.rb".freeze, "test/rbbt/segment/test_corpus.rb".freeze, "test/test_spaCy.rb".freeze, "test/test_helper.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rbbt-util>.freeze, [">= 4.0.0"])
    s.add_runtime_dependency(%q<stemmer>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<libxml-ruby>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rbbt-util>.freeze, [">= 4.0.0"])
    s.add_dependency(%q<stemmer>.freeze, [">= 0"])
    s.add_dependency(%q<libxml-ruby>.freeze, [">= 0"])
    s.add_dependency(%q<json>.freeze, [">= 0"])
  end
end

