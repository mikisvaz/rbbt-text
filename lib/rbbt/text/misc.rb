module Misc
  def self.greek_characters
    @@greek_characters ||= Rbbt.share.text.greek.tsv
  end
end
