require 'rbbt/sources/pubmed'

module Document::Corpus
  PUBMED_NAMESPACE="PMID"
  def add_pmid(pmid, type = nil, update = false)
    type = :abstract if type.nil?
    if update == false
      id = [PUBMED_NAMESPACE, pmid, type].collect{|e| e.to_s}*":"
      documents = self.documents(id)
      return documents if documents.any?
    end

    pmids = Array === pmid ? pmid : [pmid]
    type = nil if String === type and type.empty?

    res = PubMed.get_article(pmids).collect do |pmid, article|
      document = if type.to_sym == :abstract
                   Document.setup(article.abstract || "", PUBMED_NAMESPACE, pmid, :abstract, self, :corpus => self)
                 elsif type.to_sym == :title
                   Document.setup(article.title, PUBMED_NAMESPACE, pmid, :title, self)
                 else
                   raise "No FullText available for #{ pmid }" if article.full_text.nil?
                   Document.setup(article.full_text, PUBMED_NAMESPACE, pmid, :fulltext, self, :corpus => self)
                 end
      Log.debug "Loading pmid #{pmid}"
      add_document(document)
      document
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
