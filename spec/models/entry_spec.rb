
require 'set'
require "rails_helper"

describe Entry do

  before :all do
    SDBMSS::ReferenceData.create_all
  end

  describe "associations" do

    it "should use scope :with_associations" do
      Entry.with_associations.last
    end

    it "should use scope :most_recent" do
      expect(Entry.most_recent(3).length). to eq(3)
    end

  end

  describe "access methods" do

    it "should get_entries_for_manuscript" do
      entry = Entry.last
      expect(entry.get_entries_for_manuscript).to eq([])
    end

    it "should get similar entries" do
      entry = Entry.last
      SDBMSS::SimilarEntries.new(entry)
    end

    it "should get as flat hash" do
      entry = Entry.last
      expect(entry.as_flat_hash).to be_a(Hash)
    end

    it "should get cumulative_updated_at" do
      entry = Entry.last
      expect(entry.cumulative_updated_at).to be_a(Fixnum)
    end

  end

  describe "CRUD operations" do

    it "should delete properly" do
      # this exercises cascading deletes and FK constraints
      Entry.all.each do |entry|
        entry.destroy!
      end
    end

  end

end
