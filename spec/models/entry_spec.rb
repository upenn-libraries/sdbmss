
require "rails_helper"

describe Entry do

  before :all do
    SDBMSS::ReferenceData.create_all
  end

  describe "associations" do

    it "should use scope :with_associations" do
      Entry.with_associations.last
    end

  end

  describe "access methods" do

    it "should get_entries_for_manuscript" do
      expect(subject.get_entries_for_manuscript).to eq([])
    end

  end

end
