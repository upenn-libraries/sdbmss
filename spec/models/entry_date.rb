
require "rails_helper"

describe Entry do

  describe "#normalize_date" do

    it "normalizes a century date" do
      expect(EntryDate.normalize_date("11th century")).to eq(["1000", "1099"])
    end

    it "normalizes an early century date" do
      expect(EntryDate.normalize_date("early 11th century")).to eq(["1000", "1050"])
    end

    it "normalizes a late century date" do
      expect(EntryDate.normalize_date("late 6th century")).to eq(["550", "599"])
    end

    it "normalizes a mid century date" do
      expect(EntryDate.normalize_date("mid 12th century")).to eq(["1125", "1175"])
    end

    it "normalizes an approximate decade date" do
      expect(EntryDate.normalize_date("1870s")).to eq(["1870", "1879"])
    end

    it "normalizes a date range" do
      expect(EntryDate.normalize_date("567 to 1205")).to eq(["567", "1205"])
    end

    it "normalizes a date range with decade" do
      expect(EntryDate.normalize_date("567 to 1200s")).to eq(["567", "1299"])
    end

    it "normalizes a circa date" do
      expect(EntryDate.normalize_date("circa 1324")).to eq(["1324", "1324"])
    end

    it "normalizes an exact year" do
      expect(EntryDate.normalize_date("276")).to eq(["276", "276"])
    end

    it "normalizes an exact date" do
      expect(EntryDate.normalize_date("1276-10-01")).to eq(["1276-10-01", "1276-10-01"])
    end

    it "normalizes an exact date" do
      expect(EntryDate.normalize_date("January 7th, 1509")).to eq(["1509-01-07", "1509-01-07"])
    end

    it "normalizes a nonsense string" do
      expect(EntryDate.normalize_date("blah de blah")).to eq([nil,nil])
    end

  end

end
