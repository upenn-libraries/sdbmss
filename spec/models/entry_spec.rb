
require "rails_helper"

describe Entry do

  describe "associations" do

    xit "should scope :load_associations" do
      expect(Entry.find(1).load_associations).to be_nil
    end

  end

  describe "access methods" do

    it "should get_entries_for_manuscript" do
      expect(subject.get_entries_for_manuscript).to eq([])
    end

  end

end
