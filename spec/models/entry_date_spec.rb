
require "rails_helper"

describe EntryDate do

  describe "#normalize_date" do

    # Note that date ranges are end-exclusive

    it "normalizes a before date" do
      expect(EntryDate.normalize_date("before 1132")).to eq(["1033", "1133"])
    end

    it "normalizes an after date" do
      expect(EntryDate.normalize_date("after 1132")).to eq(["1132", "1232"])
    end

    it "normalizes a century date" do
      expect(EntryDate.normalize_date("eleventh century")).to eq(["1000", "1100"])
    end

    it "normalizes a century date" do
      expect(EntryDate.normalize_date("11th century")).to eq(["1000", "1100"])
    end

    it "normalizes a cent. date" do
      expect(EntryDate.normalize_date("11th cent.")).to eq(["1000", "1100"])
    end

    it "normalizes a c. date" do
      expect(EntryDate.normalize_date("11th c.")).to eq(["1000", "1100"])
    end

    it "normalizes an early century date" do
      expect(EntryDate.normalize_date("early 11th century")).to eq(["1000", "1026"])
    end

    it "normalizes a mid century date" do
      expect(EntryDate.normalize_date("mid 12th century")).to eq(["1126", "1176"])
    end

    it "normalizes a late century date" do
      expect(EntryDate.normalize_date("late 6th century")).to eq(["576", "600"])
    end

    it "normalizes a late century date" do
      expect(EntryDate.normalize_date("late sixth century")).to eq(["576", "600"])
    end

    it "normalizes second quarter of century date" do
      expect(EntryDate.normalize_date("second quarter of the 9th century")).to eq(["826", "851"])
    end

    it "normalizes first half of century date" do
      expect(EntryDate.normalize_date("first half of the 14th century")).to eq(["1300", "1351"])
    end

    it "normalizes first third of century date" do
      expect(EntryDate.normalize_date("first third of the 14th century")).to eq(["1300", "1334"])
    end

    it "normalizes an approximate decade date" do
      expect(EntryDate.normalize_date("1870s")).to eq(["1870", "1880"])
    end

    it "normalizes a date range" do
      expect(EntryDate.normalize_date("567 to 1205")).to eq(["567", "1206"])
    end

    it "normalizes a date range with decade" do
      expect(EntryDate.normalize_date("567 to 590s")).to eq(["567", "600"])
    end

    it "normalizes a circa date" do
      expect(EntryDate.normalize_date("circa 1324")).to eq(["1314", "1335"])
    end

    it "normalizes a ca. date" do
      expect(EntryDate.normalize_date("ca. 1324")).to eq(["1314", "1335"])
    end

    it "normalizes an 'about' date" do
      expect(EntryDate.normalize_date("about 1324")).to eq(["1314", "1335"])
    end

    it "normalizes an exact year" do
      expect(EntryDate.normalize_date("276")).to eq(["276", "277"])
    end

    it "normalizes an exact date" do
      expect(EntryDate.normalize_date("1276-10-01")).to eq(["1276-10-01", "1276-10-02"])
    end

    it "normalizes an exact date" do
      expect(EntryDate.normalize_date("December 1st, 1982")).to eq(["1982-12-01", "1982-12-02"])
    end

    it "normalizes an exact date" do
      expect(EntryDate.normalize_date("January 7th, 1509")).to eq(["1509-01-07", "1509-01-08"])
    end

    it "normalizes a nonsense string" do
      expect(EntryDate.normalize_date("blah de blah")).to eq([nil,nil])
    end

  end

end
