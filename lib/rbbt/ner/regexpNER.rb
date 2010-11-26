require 'rbbt-util'
require 'rbbt/bow/misc'

class RegExpNER

  def self.build_re(names, ignorecase=true)
    res = names.compact.reject{|n| n.empty?}.
      sort_by{|a| a.length}.reverse.collect{|n| Regexp.quote(n) }

    /\b(#{ res.join("|").gsub(/\\?\s/,'\s+') })\b/
  end

  def initialize(lexicon, options = {})
    options = Misc.add_defaults options, :flatten => true, :case_insensitive => true, :stopwords => nil

    if $stopwords and  (options[:stopwords].nil? || options[:stopwords] == true) 
      options[:stopwords] = $stopwords 
    else
      options[:stopwords] = []
    end

    data = TSV.new(lexicon, options)

    @index = {}
    data.collect{|code, names|
      next if code.nil? || code == ""
      if options[:stopwords].any?
        names = names.select{|n| 
          ! options[:stopwords].include?(options[:case_insensitive] ? n.downcase : n)
        } 
      end
      @index[code] = RegExpNER.build_re(names, options[:case_insensitive])
   }
  end

  def self.match_re(text, res)
    res = [res] unless Array === res

    res.collect{|re|
      text.scan(re) 
    }.flatten
  end

  def match_hash(text)
    return {} if text.nil? or text.empty?
    matches = {}
    @index.each{|code, re|
      RegExpNER.match_re(text, re).each{|match|
         matches[code] ||= []
         matches[code] << match
      }
    }
    matches
  end

  def match(text)
    match_hash(text)
  end

end

