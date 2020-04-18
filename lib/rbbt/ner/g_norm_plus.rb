require 'rbbt-util'
require 'rbbt/segment'
require 'rbbt/segment/named_entity'
module GNormPlus

  Rbbt.claim Rbbt.software.opt.GNormPlus, :install do
    url = "https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/tmTools/download/GNormPlus/GNormPlusJava.zip"
    script =<<-EOF
(cd $(opt_dir $name); sh Installation.sh; chmod +x Ab3P identify_abbr)
    EOF
    {:src => url, :commands => script}
  end

  CONFIG =<<-EOF
#===Annotation
#Attribution setting:
#FocusSpecies = Taxonomy ID
#       All: All species
#       9606: Human
#       4932: yeast
#       7227: Fly
#       10090: Mouse
#       10116: Rat
#       7955: Zebrafish
#       3702: Arabidopsis thaliana
#open: True
#close: False

[Focus Species]
	FocusSpecies = 9606
	FilterAntibody = False
[Dictionary & Model]
	DictionaryFolder = ./Dictionary
	GNRModel = ./Dictionary/GNR.Model
	SCModel = ./Dictionary/SimConcept.Model
	GeneIDMatch = True
	HomologeneID = False
	Normalization2Protein = False
	ShowUnNormalizedMention = False
	IgnoreNER = False
	DeleteTmp = True
EOF

  def self.process(texts)
    TmpFile.with_file do |tmpdir|
      Open.mkdir tmpdir

      Misc.in_dir tmpdir do
        Open.ln_s Rbbt.software.opt.GNormPlus.Dictionary.find, '.'
        Open.ln_s Rbbt.software.opt.GNormPlus["BioC.dtd"].find, '.'
        Open.ln_s Rbbt.software.opt.GNormPlus["Ab3P"].find, '.'
        Open.ln_s Rbbt.software.opt.GNormPlus["CRF"].find, '.'
        Open.mkdir 'input'
        Open.mkdir 'output'
        Open.mkdir 'tmp'

        texts.each do |name,text|
          Open.write("input/#{name}.txt") do |f|
            f.puts "#{name}|a|" << text.gsub("\n\n", "\n·")
            f.puts
          end
        end
        Open.write('config', CONFIG)
        CMD.cmd_log("java -Xmx20G -Xms20G  -jar '#{Rbbt.software.opt.GNormPlus.produce.find}/GNormPlus.jar' 'input' 'output' 'config'")

        if texts.respond_to? :key_field
          key_field = texts.key_field
        else
          key_field = "ID"
        end
        tsv = TSV.setup({}, :key_field => key_field, :fields => ["Entities"], :type => :flat)
        Dir.glob("output/*.txt").each do |file|
          name = File.basename(file).sub(".txt",'')
          entities = Open.read(file).split("\n")[1..-1].collect{|l| l.gsub(':', '·').split("\t")[1..-1] * ":"}
          tsv[name] = entities
        end

        raise "GNormPlus failed: no results found" if tsv.size == 0 && texts.size > 0

        tsv
      end
    end
  end

  def self.entities(texts)
    res = {}
    process(texts).each do |name, entities|

      segments = entities.collect do |entity|
        start, eend, literal, type, code = entity.split(":")
        literal.gsub!('·',':')

        NamedEntity.setup(literal, :offset => start.to_i, :entity_type => type, :code => code)
      end

      res[name] = segments
    end
  end
end

if __FILE__ == $0
  Log.severity = 0
  Rbbt.software.opt.GNormPlus.produce
end
