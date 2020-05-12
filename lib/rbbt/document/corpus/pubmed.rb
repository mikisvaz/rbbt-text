require 'rbbt/sources/pubmed'

module Document::Corpus
  def add_pmid(pmid, type = nil)
    pmids = Array === pmid ? pmid : [pmid]
    type = nil if String === type and type.empty?

    res = PubMed.get_article(pmids).collect do |pmid, article|
      document = if type.nil? || type.to_sym == :abstract
                   Document.setup(article.abstract || "", "PMID", pmid, :abstract, self, :corpus => self)
                 elsif type.to_sym == :title
                   Document.setup(article.title, :PMID, pmid, :title, self)
                 else
                   raise "No FullText available for #{ pmid }" if article.full_text.nil?
                   Document.setup(article.full_text, :PMID, pmid, :fulltext, self, :corpus => self)
                 end
      Log.debug "Loading pmid #{pmid}"
      add_document(document)
    end

    Document.setup(res)
  end
  
  def add_pubmed_query(query, max = 3000, type = nil)
    pmids = PubMed.query(query, max)
    add_pmid(pmids, type)
  end

  self.claim "PMID" do |id, type|
    Log.debug "Claiming #{id}"
    self.add_pmid(id, type).first
  end
end
