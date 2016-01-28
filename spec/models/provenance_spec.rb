
require "rails_helper"

describe Provenance do

  describe "#parse_observed_date" do

    # Note that date ranges are end-exclusive

    it "parses a before date" do
      expect(Provenance.parse_observed_date("before 1132")).to eq(["1033", "1133"])
    end

    it "parses an after date" do
      expect(Provenance.parse_observed_date("after 1132")).to eq(["1132", "1232"])
    end

    it "parses a century date" do
      expect(Provenance.parse_observed_date("eleventh century")).to eq(["1000", "1101"])
    end

    it "parses a century date" do
      expect(Provenance.parse_observed_date("11th century")).to eq(["1000", "1101"])
    end

    it "parses a cent. date" do
      expect(Provenance.parse_observed_date("11th cent.")).to eq(["1000", "1101"])
    end

    it "parses a c. date" do
      expect(Provenance.parse_observed_date("11th c.")).to eq(["1000", "1101"])
    end

    it "parses an early century date" do
      expect(Provenance.parse_observed_date("early 11th century")).to eq(["1000", "1026"])
    end

    it "parses a mid century date" do
      expect(Provenance.parse_observed_date("mid 12th century")).to eq(["1126", "1176"])
    end

    it "parses a late century date" do
      expect(Provenance.parse_observed_date("late 6th century")).to eq(["576", "601"])
    end

    it "parses a late century date" do
      expect(Provenance.parse_observed_date("late sixth century")).to eq(["576", "601"])
    end

    it "parses second quarter of century date" do
      expect(Provenance.parse_observed_date("second quarter of the 9th century")).to eq(["826", "851"])
    end

    it "parses first half of century date" do
      expect(Provenance.parse_observed_date("first half of the 14th century")).to eq(["1300", "1351"])
    end

    it "parses first third of century date" do
      expect(Provenance.parse_observed_date("first third of the 14th century")).to eq(["1300", "1334"])
    end

    it "parses an approximate decade date" do
      expect(Provenance.parse_observed_date("1870s")).to eq(["1870", "1880"])
    end

    it "parses a date range" do
      expect(Provenance.parse_observed_date("567 to 1205")).to eq(["567", "1206"])
    end

    it "parses a date range with decade" do
      expect(Provenance.parse_observed_date("567 to 590s")).to eq(["567", "600"])
    end

    it "parses a circa date" do
      expect(Provenance.parse_observed_date("circa 1324")).to eq(["1314", "1335"])
    end

    it "parses a ca. date" do
      expect(Provenance.parse_observed_date("ca. 1324")).to eq(["1314", "1335"])
    end

    it "parses an 'about' date" do
      expect(Provenance.parse_observed_date("about 1324")).to eq(["1314", "1335"])
    end

    it "parses an exact year" do
      expect(Provenance.parse_observed_date("276")).to eq(["276", "277"])
    end

    it "parses a month and year" do
      expect(Provenance.parse_observed_date("June 1302")).to eq(["1302-06-01", "1302-07-01"])
    end

    it "parses an exact date" do
      expect(Provenance.parse_observed_date("1276-10-01")).to eq(["1276-10-01", "1276-10-02"])
    end

    it "parses an exact date" do
      expect(Provenance.parse_observed_date("December 1st, 1982")).to eq(["1982-12-01", "1982-12-02"])
    end

    it "parses an exact date" do
      expect(Provenance.parse_observed_date("January 7th, 1509")).to eq(["1509-01-07", "1509-01-08"])
    end

    it "parses a nonsense string" do
      expect(Provenance.parse_observed_date("blah de blah")).to eq([nil,nil])
    end

    # new parsing capabilities


    it "parses returns nil upon default date parsing (Chronic) exception" do
      expect(Provenance.parse_observed_date("Tenth")).to eq([nil, nil])
    end

    it "parses a roman numeral year" do
      expect(Provenance.parse_observed_date("MCXX")).to eq(["1120", "1121"])
    end

    it "parses a before roman numeral date" do
      expect(Provenance.parse_observed_date("before MCDII")).to eq(["1303", "1403"])
    end

    it "parses an after roman numeral date" do
      expect(Provenance.parse_observed_date("after MLXXI")).to eq(["1071", "1171"])
    end

    it "parses a roman numeral century" do
      expect(Provenance.parse_observed_date("XIVth century")).to eq(["1300", "1401"])
    end

    it "parses alternative roman numeral century in format S. XVI" do
      expect(Provenance.parse_observed_date("S. XII")).to eq(["1100", "1201"])
    end

    it "parses a roman numeral cent. date" do
      expect(Provenance.parse_observed_date("Xth cent.")).to eq(["900", "1001"])
    end

    it "parses a roman numeral c. date" do
      expect(Provenance.parse_observed_date("XIth c.")).to eq(["1000", "1101"])
    end

    it "parses an early roman numeral century date" do
      expect(Provenance.parse_observed_date("early S. XI")).to eq(["1000", "1026"])
    end

    it "parses a mid roman numeral century date" do
      expect(Provenance.parse_observed_date("mid XIIth century")).to eq(["1126", "1176"])
    end

    it "parses a late roman numeral century date" do
      expect(Provenance.parse_observed_date("late VIth century")).to eq(["576", "601"])
    end

    it "parses second quarter of roman numeral century date" do
      expect(Provenance.parse_observed_date("second quarter of S. IX")).to eq(["826", "851"])
    end

    it "parses first half of roman numeral century date" do
      expect(Provenance.parse_observed_date("first half of the XIVth century")).to eq(["1300", "1351"])
    end

    it "parses first third of roman numeral century date" do
      expect(Provenance.parse_observed_date("first third of the S. XIV")).to eq(["1300", "1334"])
    end

    it "parses a roman numeral date range" do
      expect(Provenance.parse_observed_date("DLXVII to MCCV")).to eq(["567", "1206"])
    end

    it "parses a roman numeral circa date" do
      expect(Provenance.parse_observed_date("circa MCCCXXIV")).to eq(["1314", "1335"])
    end

    it "parses a roman numeral ca. date" do
      expect(Provenance.parse_observed_date("ca. MCCCXXIV")).to eq(["1314", "1335"])
    end

    it "parses a roman numeral 'about' date" do
      expect(Provenance.parse_observed_date("about MCCCXXIV")).to eq(["1314", "1335"])
    end

    it "parses roman numeral dates - case insensitive" do
      expect(Provenance.parse_observed_date("about MccCxxIv")).to eq(["1314", "1335"])
      expect(Provenance.parse_observed_date("First hALf of the xivTH century")).to eq(["1300", "1351"])
    end

  end

end
