require "rails_helper"

describe "De Ricci Game", :js => true do
  context "when user is logged in " do
    before :all do
      @admin_user = User.where(role: "admin").first
    end

    before :each do
      login(@admin_user, 'somethingunguessable')
    end
  end
end