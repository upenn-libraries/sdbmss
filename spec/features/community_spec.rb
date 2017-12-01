require "rails_helper"

describe "Community", :js => true do

  context "when user is logged in" do
    before :all do
      @admin_user = User.where(role: "admin").first
    end

    before :each do
      login(@admin_user, 'somethingunguessable')
    end

    it "should load the community page" do
      visit community_path
      expect(page).to have_content("Thank you for supporting the SDBM community")
      expect(page).to have_content("lransom")
    end

    it "should show community stats by week" do
      visit community_path
      expect(page).to have_content("Thank you for supporting the SDBM community")
      select("Week", from: 'measure')
      select('6', from: 'quantity')
      find('#submit').click
      expect(page).to have_content("Thank you for supporting the SDBM community")
      expect(page).to have_content("lransom")
    end

    it "should show community stats by day" do
      visit community_path
      expect(page).to have_content("Thank you for supporting the SDBM community")
      select("Day", from: 'measure')
      select('1', from: 'quantity')
      find('#submit').click
      expect(page).to have_content("Thank you for supporting the SDBM community")
      expect(page).to have_content("lransom")
    end

  end
end