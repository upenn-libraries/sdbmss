require 'rails_helper'

RSpec.describe DericciRecord, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "#public_id" do
    it "returns correctly formatted public_id" do
      record = create(:dericci_record)
      expect(record.public_id).to eq("De Ricci #{record.id}")
    end
  end

  describe "#bookmark_details" do
    it "returns a hash of record details" do
      record = create(:dericci_record, name: "Test Record", cards: 5)
      details = record.bookmark_details
      expect(details["Name"]).to eq("Test Record")
      expect(details["Cards"]).to eq(5)
    end
  end
end
