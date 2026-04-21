require 'rails_helper'

RSpec.describe EntryDate, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "validations" do
    it "is valid with correct dates" do
      entry_date = build(:entry_date, date_normalized_start: 1400, date_normalized_end: 1500)
      expect(entry_date).to be_valid
    end

    it "is invalid if start is after end" do
      entry_date = build(:entry_date, date_normalized_start: 1500, date_normalized_end: 1400)
      expect(entry_date).not_to be_valid
    end
  end

  describe ".parse_observed_date" do
    it "parses exact years" do
      expect(EntryDate.parse_observed_date("1450")).to eq([1450, 1451])
    end

    it "parses chronic dates" do
      expect(EntryDate.parse_observed_date("2020-01-01")).to eq([2020, 2021])
    end
  end

  describe "#normalize_observed_date" do
    it "populates normalized fields" do
      entry_date = build(:entry_date, observed_date: "1450", date_normalized_start: nil, date_normalized_end: nil)
      entry_date.normalize_observed_date
      expect(entry_date.date_normalized_start).to eq("1450")
      expect(entry_date.date_normalized_end).to eq("1451")
    end
  end
end
