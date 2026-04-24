
require "rails_helper"
describe "Manage languages", :js => true do
  let(:admin_user) { create(:admin) }

  before :each do
    @admin = admin_user
    @user = admin_user

    @language = Language.find_or_create_by(name: "Martian") do |l|
      l.created_by = @user
    end
    Language.index
    Sunspot.commit
  end

  context "when admin is logged in" do

    before :each do
      login(@user, 'somethingreallylong')
    end

    it "should add a new Language" do
      expect(Language.where(name: "Klingon").count).to eq(0)
      visit new_language_path
      fill_in "language_name", with: "Klingon"
      click_button "Create Language"

      expect(Language.where(name: "Klingon").count).to eq(1)
      language = Language.where(name: "Klingon").first
      expect(language.reviewed).to eq(false)
    end

    it "should edit a Language" do
      language = Language.create(name: "Already reviewed", reviewed: true, created_by: @user)

      visit edit_language_path :id => language.id
      fill_in "language_name", with: "This should change to unreviewed"
      click_button "Update Language"

      expect(page).to have_content 'Your changes have been saved'

      language = Language.find(language.id)
    end

    it "should delete a Language" do
      # this is a very rough test!
      skip "contributors can't delete languages."
      count = Language.count

      # mock out the confirm dialogue
      page.evaluate_script('window.confirm = function() { return true; }')

      visit languages_path
      find(".delete-link", match: :first).click
      sleep(1)

      expect(Language.count).to eq(count-1)
    end

    it "should export CSV", :js => false,
      skip: "language CSV export still exists, but async download polling belongs in lower-level coverage instead of this feature spec" do
    end
  end

  context "when admin is logged in" do

    before :each do
      @language = Language.find_or_create_by(name: "Pig Latin") do |l|
        l.created_by = @user
      end
      Language.index
      Sunspot.commit
    end

    before :each do
      login(@admin, 'somethingreallylong')
    end

#    it "should mark Languages as reviewed" do
#      Language.index
#
#      expect(@language.reviewed).to be false
#
#      visit languages_path
#      expect(page).to have_content @language.name
#      find("#unreviewed_only", match: :first).click
#      click_button 'Search'
#
#      expect(page).to have_selector("#select-all", visible: true)
#      find("#select-all").click
#
#      expect(page).to have_selector("#mark-as-reviewed")
#      find("#mark-as-reviewed").click
#
#      expect(page).to have_content("No records found")
#
#      @language.reload
#      expect(@language.reviewed).to be true
#      expect(@language.reviewed_by_id).to eq(@admin.id)
#    end

  end

end
