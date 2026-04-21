require 'rails_helper'

RSpec.describe Source, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "validations" do
    it "is valid with a title and source_type" do
      source = build(:edit_test_source)
      expect(source).to be_valid
    end

    it "is invalid without a source_type" do
      source = build(:edit_test_source, source_type: nil)
      expect(source).not_to be_valid
    end

    context "when source_type is auction_catalog" do
      let(:auction_type) { SourceType.find_by(name: SourceType::AUCTION_CATALOG) }

      it "disallows an author" do
        source = build(:edit_test_source, source_type: auction_type, author: "Some Author")
        expect(source).not_to be_valid
        expect(source.errors[:author]).to include(/not allowed/)
      end

      it "allows a title" do
        source = build(:edit_test_source, source_type: auction_type, title: "Auction Title", author: nil)
        expect(source).to be_valid
      end
    end

    context "when source_type is online" do
      let(:online_type) { SourceType.find_by(name: SourceType::ONLINE) }

      it "disallows a date" do
        source = build(:edit_test_source, source_type: online_type, date: "20230101")
        expect(source).not_to be_valid
        expect(source.errors[:date]).to include(/not allowed/)
      end

      it "disallows an author" do
        source = build(:edit_test_source, source_type: online_type, author: "Some Author")
        expect(source).not_to be_valid
        expect(source.errors[:author]).to include(/not allowed/)
      end
    end
  end

  describe "scopes" do
    describe ".most_recent" do
      it "returns the specified number of most recent sources" do
        create_list(:edit_test_source, 3)
        expect(Source.most_recent(2).length).to eq(2)
      end
    end
  end

  describe "#display_value" do
    let(:source_type) { SourceType.find_by(name: SourceType::COLLECTION_CATALOG) }
    let(:agent) { Name.find_or_create_agent("Test Agent") }
    
    it "returns a formatted string with date, agent, and title" do
      source = create(:edit_test_source, 
                      source_type: source_type, 
                      title: "Test Title", 
                      date: "20200000",
                      author: nil)
      source.source_agents.create!(role: SourceAgent::ROLE_INSTITUTION, agent: agent)
      
      # format_fuzzy_date("20200000") -> "2020"
      expect(source.display_value).to include("2020")
      expect(source.display_value).to include("Test Agent")
      expect(source.display_value).to include("Test Title")
    end
  end

  describe "#merge_into" do
    let(:admin) { create(:admin) }
    let(:source1) { create(:edit_test_source, title: "Source 1", created_by: admin) }
    let(:source2) { create(:edit_test_source, title: "Source 2", created_by: admin) }
    let!(:entry) { create(:edit_test_entry, source: source1, created_by: admin) }

    before do
      allow(SDBMSS::IndexJob).to receive(:perform_later)
    end

    it "moves entries from the source to the target" do
      expect {
        source1.merge_into(source2)
      }.to change { entry.reload.source_id }.from(source1.id).to(source2.id)
    end

    it "marks the source as deleted" do
      source1.merge_into(source2)
      expect(source1.reload.deleted).to be true
    end

    it "queues a reindex job for affected entries" do
      expect(SDBMSS::IndexJob).to receive(:perform_later).with("Entry", [entry.id])
      source1.merge_into(source2)
    end
  end
end
