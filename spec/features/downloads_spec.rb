require "rails_helper"

describe "Downloads", :js => true do

  context "when user is logged in " do
    before :all do
      @admin_user = User.where(role: "admin").first
    end

    before :each do
      login(@admin_user, 'somethingunguessable')
    end

    it "should show allow the user to attempt to export search results" do
      visit names_path
      expect(page).to have_content(Name.last.name)
      find('#export-csv').click
      expect(page).to have_content('Download CSV')
      click_button 'Yes'
      expect(page).to have_content('CSV Export is being prepared')
      visit downloads_path
      expect(page).to have_content('names.csv')
      click_link 'names.csv'
    end

  end

end
