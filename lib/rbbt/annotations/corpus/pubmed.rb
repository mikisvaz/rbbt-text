class Corpus
  def add_pmid(pmid, abstract = nil)
    pmids = Array === pmid ? pmid : [pmid]
    PubMed.get_article(pmids).each do |pmid, article|
      if abstract or (abstract.nil?  and article.pdf_url.nil?)
        add_document(article.text, :pubmed, pmid, :abstract) unless exists?(:pubmed, pmid, :abstract)
      else
        raise "No FullText available for #{ pmid }" if article.pdf_url.nil?
        add_document(article.full_text, :pubmed, pmid, :fulltext) unless exists?(:pubmed, pmid, :fulltext)
      end
    end
  end
  
  def add_pubmed_query(query, max, abstract = nil)
    pmids = PubMed.query(query, max)
    add_pmid(pmids, abstract)
  end
end
