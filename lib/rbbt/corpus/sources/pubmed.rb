require 'rbbt/sources/pubmed'

class Corpus

  NAMESPACES = {} unless defined? NAMESPACES
  NAMESPACES[:pubmed] = :add_pmid

  def add_pmid(pmid, type = nil)
    pmids = Array === pmid ? pmid : [pmid]
    type = nil if String === type and type.empty?

    PubMed.get_article(pmids).collect do |pmid, article|
      if (type.nil? and article.pdf_url.nil?) or (not type.nil? and type.to_sym === :abstract)
        add_document(article.text, :pubmed, pmid, :abstract)
      else
        raise "No FullText available for #{ pmid }" if article.pdf_url.nil?
        add_document(article.full_text, :pubmed, pmid, :fulltext)
      end
    end
  end
  
  def add_pubmed_query(query, max, type = nil)
    pmids = PubMed.query(query, max)
    add_pmid(pmids, type)
  end
end
