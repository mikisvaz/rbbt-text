require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/ner/brat'

class TestBrat < Test::Unit::TestCase
  def test_load
    text =<<-EOF
T2	DBTF 52 55	Nrl
#2	AnnotatorNotes T2	4901
T3	NONDBTF 80 89	rhodopsin
#3	AnnotatorNotes T3	6010
T4	BIOLOGICALPROCESS 90 105	gene expression
#4	AnnotatorNotes T4	-
T5	DBTF 127 130	Nrl
#5	AnnotatorNotes T5	4901
T7	MOLECULARFUNCTION 197 204	binding
#7	AnnotatorNotes T7	-
T8	PHENOTYPE 241 252	extended AP
#8	AnnotatorNotes T8	-
T10	DBTF 331 334	Nrl
#10	AnnotatorNotes T10	4901
T11	TISSUE 381 399	photoreceptor cell
#11	AnnotatorNotes T11	-
T12	NONDBTF 414 423	rhodopsin
#12	AnnotatorNotes T12	6010
T13	CELLULARCOMPONENT 494 501	nuclear
#13	AnnotatorNotes T13	-
T14	TISSUE 548 572	retinoblastoma cell line
#14	AnnotatorNotes T14	-
T17	NONDBTF 660 669	rhodopsin
#17	AnnotatorNotes T17	6010
T18	DBTF 676 679	Nrl
#18	AnnotatorNotes T18	4901
T19	CELLULARCOMPONENT 749 764	protein complex
#19	AnnotatorNotes T19	-
T20	DBTF 797 800	Nrl
#20	AnnotatorNotes T20	4901
T21	DBTF 853 856	Nrl
#21	AnnotatorNotes T21	4901
T22	MOLECULARFUNCTION 882 892	luciferase
#22	AnnotatorNotes T22	-
T23	DBTF 943 946	Nrl
#23	AnnotatorNotes T23	4901
T24	NONDBTF 989 998	rhodopsin
#24	AnnotatorNotes T24	6010
T26	DBTF 1110 1113	Nrl
#26	AnnotatorNotes T26	4901
T27	DBTF 1224 1227	Nrl
#27	AnnotatorNotes T27	4901
T28	DBTF 1271 1274	Nrl
#28	AnnotatorNotes T28	4901
T30	DBTF 1385 1388	Nrl
#30	AnnotatorNotes T30	4901
R1	ACTIVATION Arg1:T2 Arg2:T3
R2	ACTIVATION Arg1:T10 Arg2:T12
R3	ACTIVATION Arg1:T23 Arg2:T24
T1	DBTF 250 254	AP-1
    EOF

    io = StringIO.new text
    iii Brat.load io

  end
end

