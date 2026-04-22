require "rails_helper"

describe Activity do

  let(:user) { create(:user) }

  describe "#format_event" do
    [
      ["destroy",          "deleted"],
      ["update",           "edited"],
      ["create",           "added"],
      ["mark_as_reviewed", "marked as reviewed"],
      ["merge",            "merged"],
    ].each do |event, expected|
      it "returns '#{expected}' for '#{event}'" do
        activity = Activity.new(event: event, item_type: "Entry", item_id: 1)
        expect(activity.format_event).to eq(expected)
      end
    end

    it "returns the raw event string for unknown events" do
      activity = Activity.new(event: "custom_action", item_type: "Entry", item_id: 1)
      expect(activity.format_event).to eq("custom_action")
    end
  end

  describe "#link" do
    context "when item_type is User" do
      it "returns the accounts path" do
        activity = Activity.new(event: "create", item_type: "User", item_id: user.id, item: user)
        expect(activity.link).to eq("/accounts/#{user.id}")
      end
    end

    context "when item_type is EntryManuscript with a manuscript" do
      it "returns the manuscript path" do
        source     = Source.create!(source_type: SourceType.auction_catalog, created_by: user)
        entry      = Entry.create!(source: source, created_by: user)
        manuscript = Manuscript.create!(created_by: user)
        em         = EntryManuscript.create!(
          entry: entry, manuscript: manuscript,
          relation_type: EntryManuscript::TYPE_RELATION_IS, created_by: user
        )
        activity = Activity.new(event: "create", item_type: "EntryManuscript", item_id: em.id, item: em)
        expect(activity.link).to eq("/manuscripts/#{manuscript.id}")
      end
    end

    context "when item_type is EntryManuscript without a manuscript" do
      it "returns the dashboard path" do
        activity = Activity.new(event: "create", item_type: "EntryManuscript", item_id: 0)
        allow(activity).to receive(:item).and_return(double("EntryManuscript", manuscript: nil))
        expect(activity.link).to eq("/dashboard")
      end
    end

    context "when item_type is something else" do
      it "returns the pluralized resource path" do
        source   = Source.create!(source_type: SourceType.auction_catalog, created_by: user)
        activity = Activity.new(event: "create", item_type: "Source", item_id: source.id, item: source)
        expect(activity.link).to eq("/sources/#{source.id}")
      end
    end
  end

end
