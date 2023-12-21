require 'rbbt/sources/pubmed'

module Document::Corpus
  PUBMED_NAMESPACE="PMID"
  def add_pmid(pmid, type = :title_and_abstract, update = false)
    type = :title_and_abstract if type.nil?

    if ! (update || Array === pmid)
      id = [PUBMED_NAMESPACE, pmid, type].collect{|e| e.to_s}*":"
      documents = self.documents(id)
      return documents.first if documents.any?
    end

    pmids = Array === pmid ? pmid : [pmid]
    type = nil if String === type and type.empty?

    res = PubMed.get_article(pmids).collect do |pmid, article|
      document = if type.to_sym == :abstract
                   Document.setup(article.abstract || "", PUBMED_NAMESPACE, pmid, type.to_sym , self, :corpus => self)
                 elsif type.to_sym == :title
                   Document.setup(article.title || "", PUBMED_NAMESPACE, pmid, type.to_sym, self)
                 elsif type.to_sym == :title_and_abstract
                   title = article.title
                   abstract = article.abstract

                   if title.nil? || title == ""
                     text = article.abstract
                     text = "" if text.nil?
                   else
                     title = title + "." unless title.end_with?(".")

                     text = title + " " + abstract if abstract && ! abstract.empty?
                   end

                   Document.setup(text, PUBMED_NAMESPACE, pmid, type.to_sym, self)
                 else
                   raise "No FullText available for #{ pmid }" if article.full_text.nil?
                   Document.setup(article.full_text, PUBMED_NAMESPACE, pmid, :fulltext, self, :corpus => self)
                 end
      Log.debug "Loading pmid #{pmid}"
      add_document(document) if document
      document
    end

    if Array === pmid
      corpus = res.first.corpus if res.first
      Document.setup(res, :corpus => corpus)
    else
      res = res.first
    end

    res
  end
  
  def add_pubmed_query(query, max = 3000, type = nil)
    pmids = PubMed.query(query, max)
    add_pmid(pmids, type)
  end

  self.claim "PMID" do |id,type,update|
    Log.debug "Claiming #{id}"
    self.add_pmid(id, type,update)
  end
end
