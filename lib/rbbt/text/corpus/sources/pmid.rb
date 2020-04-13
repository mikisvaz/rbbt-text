require 'rbbt/sources/pubmed'

class Corpus

  NAMESPACES = {} unless defined? NAMESPACES
  NAMESPACES[:pubmed] = :add_pmid

  def add_pmid(pmid, type = nil)
    pmids = Array === pmid ? pmid : [pmid]
    type = nil if String === type and type.empty?

    PubMed.get_article(pmids).collect do |pmid, article|
      Log.debug "Loading pmid #{pmid}"
      if type.nil? || type.to_sym == :abstract
        add_document(article.abstract || "", :PMID, pmid, :abstract)
      elsif type.to_sym == :title
        add_document(article.title, :PMID, pmid, :title)
      else
        raise "No FullText available for #{ pmid }" if article.full_text.nil?
        add_document(article.full_text, :PMID, pmid, :fulltext)
      end
    end
  end
  
  def add_pubmed_query(query, max = 3000, type = nil)
    pmids = PubMed.query(query, max)
    add_pmid(pmids, type)
  end

  self.claim "PMID" do |id, type|
    Log.debug "Claiming #{id}"
    self.add_pmid(id, type)
  end
end
