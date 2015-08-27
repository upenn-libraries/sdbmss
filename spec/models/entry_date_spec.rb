
require "rails_helper"

describe EntryDate do

  describe "#parse_observed_date" do

    # Note that date ranges are end-exclusive

    it "parses a before date" do
      expect(EntryDate.parse_observed_date("before 1132")).to eq(["1033", "1133"])
    end

    it "parses an after date" do
      expect(EntryDate.parse_observed_date("after 1132")).to eq(["1132", "1232"])
    end

    it "parses a century date" do
      expect(EntryDate.parse_observed_date("eleventh century")).to eq(["1000", "1101"])
    end

    it "parses a century date" do
      expect(EntryDate.parse_observed_date("11th century")).to eq(["1000", "1101"])
    end

    it "parses a cent. date" do
      expect(EntryDate.parse_observed_date("11th cent.")).to eq(["1000", "1101"])
    end

    it "parses a c. date" do
      expect(EntryDate.parse_observed_date("11th c.")).to eq(["1000", "1101"])
    end

    it "parses an early century date" do
      expect(EntryDate.parse_observed_date("early 11th century")).to eq(["1000", "1026"])
    end

    it "parses a mid century date" do
      expect(EntryDate.parse_observed_date("mid 12th century")).to eq(["1126", "1176"])
    end

    it "parses a late century date" do
      expect(EntryDate.parse_observed_date("late 6th century")).to eq(["576", "601"])
    end

    it "parses a late century date" do
      expect(EntryDate.parse_observed_date("late sixth century")).to eq(["576", "601"])
    end

    it "parses second quarter of century date" do
      expect(EntryDate.parse_observed_date("second quarter of the 9th century")).to eq(["826", "851"])
    end

    it "parses first half of century date" do
      expect(EntryDate.parse_observed_date("first half of the 14th century")).to eq(["1300", "1351"])
    end

    it "parses first third of century date" do
      expect(EntryDate.parse_observed_date("first third of the 14th century")).to eq(["1300", "1334"])
    end

    it "parses an approximate decade date" do
      expect(EntryDate.parse_observed_date("1870s")).to eq(["1870", "1880"])
    end

    it "parses a date range" do
      expect(EntryDate.parse_observed_date("567 to 1205")).to eq(["567", "1206"])
    end

    it "parses a date range with decade" do
      expect(EntryDate.parse_observed_date("567 to 590s")).to eq(["567", "600"])
    end

    it "parses a circa date" do
      expect(EntryDate.parse_observed_date("circa 1324")).to eq(["1314", "1335"])
    end

    it "parses a ca. date" do
      expect(EntryDate.parse_observed_date("ca. 1324")).to eq(["1314", "1335"])
    end

    it "parses an 'about' date" do
      expect(EntryDate.parse_observed_date("about 1324")).to eq(["1314", "1335"])
    end

    it "parses an exact year" do
      expect(EntryDate.parse_observed_date("276")).to eq(["276", "277"])
    end

    it "parses an exact date" do
      expect(EntryDate.parse_observed_date("1276-10-01")).to eq(["1276", "1277"])
    end

    it "parses an exact date" do
      expect(EntryDate.parse_observed_date("December 1st, 1982")).to eq(["1982", "1983"])
    end

    it "parses an exact date" do
      expect(EntryDate.parse_observed_date("January 7th, 1509")).to eq(["1509", "1510"])
    end

    it "parses a nonsense string" do
      expect(EntryDate.parse_observed_date("blah de blah")).to eq([nil,nil])
    end

  end

end
