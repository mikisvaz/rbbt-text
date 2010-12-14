
module NamedEntity
  def self.annotate(string, type = nil, score = nil, range = nil)
    string.extend NamedEntity
    string.type = type
    string.score = score
    string.range = range
  end

  attr_accessor :type, :score, :range
end
