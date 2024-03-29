require 'rbbt'
require 'rbbt/util/open'

Rbbt.share.wordlists.trigger_terms.define_as_url "http://zope.bioinfo.cnio.es/hpylori/pubmedxml2dir_files/ppi_trigger_term_table.txt"

$stopwords     = Rbbt.share.wordlists.stopwords.read.scan(/\w+/)

$greek = {
  "alpha"   => "a",
  "beta"    => "b",
  "gamma"   => "g",
  "delta"   => "d",
  "epsilon" => "e",
  "zeta"    => "z",
  "eta"     => "e",
  "theta"   => "th",
  "iota"    => "i",
  "kappa"   => "k",
  "lambda"  => "l",
  "mu"      => "m",
  "nu"      => "n",
  "xi"      => "x",
  "omicron" => "o",
  "pi"      => "p",
  "rho"     => "r",
  "sigma"   => "s",
  "tau"     => "t",
  "upsilon" => "u",
  "phi"     => "ph",
  "chi"     => "ch",
  "psi"     => "ps",
  "omega"   => "o"
}

$inverse_greek = Hash.new
$greek.each{|l,s| $inverse_greek[s] = l }

class String
  CONSONANTS = []
  if File.exist? File.join(Rbbt.datadir, 'wordlists/consonants')
    Object::Open.read(File.join(Rbbt.datadir, 'wordlists/consonants')).each_line{|l| CONSONANTS << l.chomp}
  end

  # Uses heuristics to checks if a string seems like a special word, like a gene name.
  def is_special?
    # Only consonants
    return true if self =~ /^[bcdfghjklmnpqrstvwxz]+$/i

    # Not a word
    return false if self =~ /[^\s]\s[^\s]/;
    return false if self.length < 3;
    # Alphanumeric
    return true if self =~ /[0-9]/ &&  self =~ /[a-z]/i
    # All Caps
    return true if self =~ /[A-Z]{2,}/;
    # Caps Mix
    return true if self =~ /[a-z][A-Z]/;
    # All consonants
    return true if self =~ /^[a-z]$/i && self !~ /[aeiou]/i
    # Dashed word
    return true if self =~ /(^\w-|-\w$)/
    # To many consonants (very heuristic)
    if self =~ /([^aeiouy]{3,})/i && !CONSONANTS.include?($1.downcase)
      return true
    end

    return false
  end

  # Turns the first letter to lowercase
  def downcase_first
    return "" if self == ""
    letters = self.scan(/./)
    letters[0].downcase!
    letters.join("")
  end

  # Turns a roman number into arabic form is possible. Just simple
  # romans only...
  def arabic
    return 1 if self =~ /^I$/;
    return 2 if self =~ /^II$/;
    return 3 if self =~ /^III$/;
    return 4 if self =~ /^IV$/;
    return 5 if self =~ /^V$/;
    return 10 if self =~ /^X$/;

    return nil
  end
end

