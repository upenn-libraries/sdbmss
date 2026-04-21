require 'rails_helper'

RSpec.describe Watch, type: :model do
  describe "validations" do
    it "is valid with a user and watched record" do
      watch = build(:watch)
      expect(watch).to be_valid
    end

    it "prevents duplicate watches for the same record and user" do
      user = create(:user)
      entry = create(:edit_test_entry)
      create(:watch, user: user, watched: entry)
      
      duplicate = build(:watch, user: user, watched: entry)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include(/only watch a record once/)
    end
  end
end
