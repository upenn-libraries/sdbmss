
require "rails_helper"
require "csv"

describe "Manage languages", :js => true do

  before :all do
    @admin = User.create!(
      email: 'adminuser@testlanguage.com',
      username: 'admin',
      password: 'somethingunguessable',
      role: 'admin',
    )
    @user = User.create!(
      email: 'testuser@testlanguage.com',
      username: 'languagetestuser',
      password: 'somethingunguessable',
      role: 'admin'
    )
    @language = Language.create!(
      name: "Martian",
      created_by: @user,
    )
  end

  context "when contributor is logged in" do

    before :each do
      visit new_user_session_path
      fill_in 'user_login', :with => @user.username
      fill_in 'user_password', :with => 'somethingunguessable'
      click_button 'Log in'
      expect(page).to have_content 'Signed in successfully'
    end

    it "should show list of Languages" do
      Language.index
      visit languages_path
      expect(page).to have_content @language.name
    end

    # poltergeist has trouble loading JSON, so we don't use it
    it "should do search for Language", js: false do
      Language.create!(name: "Something new")
      Language.create!(name: "Something old")
      Language.create!(name: "Something else")
      Language.create!(name: "Something zzz")

      Language.reindex

      s = Language.search do
        fulltext "something", :fields => [:name]
      end

      expect(s.total).to eq(4)

      visit search_languages_path(name: "something", format: "json")
      response = JSON.parse(page.source)
      expect(response).to be_a(Hash)
      expect(response["total"]).to eq(4)

      visit search_languages_path(name: "Something old", format: "json")
      response = JSON.parse(page.source)
      expect(response).to be_a(Hash)
      expect(response["total"]).to eq(1)
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
      expect(language.reviewed).to be(false)
    end

    it "should delete a Language" do
      # this is a very rough test!
      skip "contributors can't delete languages."
      count = Language.count

      # mock out the confirm dialogue
      page.evaluate_script('window.confirm = function() { return true; }')

      visit languages_path
      first(".delete-link").click
      sleep(1)

      expect(Language.count).to eq(count-1)
    end

    # poltergeist has trouble loading the csv, so we don't use it
    it "should export CSV", :js => false do
      skip "csv export uses more complicated ajax polling, disabled test for now"
      Language.create!(name: "Should appear in export")
      Language.index
      visit search_languages_path(format: :csv)
      found = false
      CSV.parse(page.source, headers: true) do |row|
        found = true if row["name"] == "Should appear in export"
      end
      expect(found).to eq(true)
    end
  end

  context "when admin is logged in" do

    before :all do
      @language = Language.create!(
        name: "Pig Latin",
        created_by: @user,
      )
    end

    before :each do
      visit new_user_session_path
      fill_in 'user_login', :with => @admin.username
      fill_in 'user_password', :with => 'somethingunguessable'
      click_button 'Log in'
      expect(page).to have_content 'Signed in successfully'
    end

    it "should show list of Languages" do
      Language.index
      visit languages_path
      expect(page).to have_content @language.name
    end

#    it "should mark Languages as reviewed" do
#      Language.index
#
#      expect(@language.reviewed).to be false
#
#      visit languages_path
#      expect(page).to have_content @language.name
#      first("#unreviewed_only").click
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
