require 'rails_helper'

RSpec.describe Entry, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "validations" do
    let(:source_type) { create(:source_type, name: SourceType::AUCTION_CATALOG, entries_transaction_field: 'sale') }
    let(:source) { create(:edit_test_source, source_type: source_type) }

    it "is valid with a source and correct transaction_type" do
      entry = build(:edit_test_entry, source: source, transaction_type: 'sale')
      expect(entry).to be_valid
    end

    it "is invalid with a transaction_type not allowed by source_type" do
      entry = build(:edit_test_entry, source: source, transaction_type: 'gift')
      expect(entry).not_to be_valid
      expect(entry.errors[:transaction_type]).to include(/isn't valid for source type/)
    end

    it "is invalid with an institution when source_type disallows it" do
      source_type.update!(entries_have_institution_field: false)
      institution = Name.find_or_create_agent("Test Institution")
      entry = build(:edit_test_entry, source: source, transaction_type: 'sale', institution: institution)
      expect(entry).not_to be_valid
      expect(entry.errors[:institution]).to include(/isn't allowed to be populated/)
    end

    it "validates numericality of physical attributes" do
      entry = build(:edit_test_entry, source: source, folios: "abc")
      expect(entry).not_to be_valid
      expect(entry.errors[:folios]).to include("is not a number")
    end
  end

  describe "counter management" do
    let(:admin) { create(:admin) }
    let(:source) { create(:edit_test_source, created_by: admin) }
    let(:author) { Name.find_or_create_agent("Author Name") }
    let(:entry) { create(:edit_test_entry, source: source, created_by: admin) }

    before do
      EntryAuthor.create!(entry: entry, author: author)
      author.reload
      # Ensure counter is synced before test
      Name.update_counters(author.id, authors_count: author.author_entries.count - author.authors_count)
      author.reload
    end

    it "decrements counters when entry is deleted" do
      initial_count = author.authors_count
      entry.decrement_counters
      expect(author.reload.authors_count).to eq(initial_count - 1)
    end
  end

  describe "#as_flat_hash" do
    let(:entry) { create(:edit_test_entry) }

    it "returns a hash with expected keys" do
      hash = entry.as_flat_hash
      expect(hash).to include(:id, :source_title, :source_date, :titles, :authors)
    end

    it "includes coordinates when csv option is present" do
      place = create(:place, latitude: 10.0, longitude: 20.0)
      entry.entry_places.create!(place: place)
      hash = entry.as_flat_hash(options: { csv: true })
      expect(hash[:coordinates]).to eq("(10.0,20.0)")
    end
  end

  describe "#to_citation" do
    let(:entry) { create(:edit_test_entry) }

    it "contains the public_id and current date" do
      citation = entry.to_citation
      expect(citation).to include(entry.public_id)
      expect(citation).to include(DateTime.now.year.to_s)
    end
  end
end
