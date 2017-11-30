
require "rails_helper"

describe "Dashboard", :js => true do

  context "when user is logged in " do
    before :all do
      @admin_user = User.where(role: "admin").first
    end

    before :each do
      login(@admin_user, 'somethingunguessable')
    end

    it "should show contributions tab of dashboard page" do
      visit dashboard_contributions_path

      expect(page).to have_content("Entries You Contributed")
      expect(page).to have_content(@admin_user.to_s)
    end


    it "should show activity tab of dashboard page" do
      visit dashboard_activity_path

      expect(page).to have_content("There is no recent activity to display")
    end

    # fix me: need check for when there is content in activity & contributions
    
  end

end
