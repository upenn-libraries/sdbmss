
require "rails_helper"
require "csv"

describe "Manage places", :js => true do

  before :all do
    @admin = User.where(role: "admin").first
    @user = User.where(role: "admin").first

    @place = Place.create!(
      name: "Martian",
      created_by: @user,
    )
  end

  context "when contributor is logged in" do

    before :each do
      login(@user, 'somethingunguessable')
    end

    it "should show list of Places" do
      Place.index
      visit places_path
      expect(page).to have_content @place.name
    end

    # poltergeist has trouble loading JSON, so we don't use it
    it "should do search for Place", js: false do
      Place.create!(name: "Something new")
      Place.create!(name: "Something old")
      Place.create!(name: "Something else")
      Place.create!(name: "Something zzz")

      Place.reindex

      s = Place.search do
        fulltext "something", :fields => [:name]
      end

      expect(s.total).to eq(4)

      visit search_places_path(name: "something", format: "json")
      response = JSON.parse(page.source)
      expect(response).to be_a(Hash)
      expect(response["total"]).to eq(4)

      visit search_places_path(name: "Something old", format: "json")
      response = JSON.parse(page.source)
      expect(response).to be_a(Hash)
      expect(response["total"]).to eq(1)
    end

    it "should add a new Place" do
      expect(Place.where(name: "Klingon").count).to eq(0)
      visit new_place_path
      fill_in "place_name", with: "Klingon"
      click_button "Create Place"

      expect(Place.where(name: "Klingon").count).to eq(1)
      place = Place.where(name: "Klingon").first
      expect(place.reviewed).to eq(false)
    end

    it "should edit a Place" do
      place = Place.create(name: "Already reviewed", reviewed: true, created_by: @user)

      visit edit_place_path :id => place.id
      fill_in "place_name", with: "This should change to unreviewed"
      click_button "Update Place"

      expect(page).to have_content 'Your changes have been saved'

      place = Place.find(place.id)
    end

    it "should delete a Place" do
      # this is a very rough test!
      skip "contributors can't delete places."
      count = Place.count

      # mock out the confirm dialogue
      page.evaluate_script('window.confirm = function() { return true; }')

      visit places_path
      first(".delete-link").click
      sleep(1)

      expect(Place.count).to eq(count-1)
    end

    # poltergeist has trouble loading the csv, so we don't use it
    it "should export CSV", :js => false do
      skip "csv export uses more complicated ajax polling, disabled test for now"
      Place.create!(name: "Should appear in export")
      Place.index
      visit search_places_path(format: :csv)
      found = false
      CSV.parse(page.source, headers: true) do |row|
        found = true if row["name"] == "Should appear in export"
      end
      expect(found).to eq(true)
    end
  end

  context "when admin is logged in" do

    before :all do
      @place = Place.create!(
        name: "Pig Latin",
        created_by: @user,
      )
    end

    before :each do
      login(@admin, 'somethingunguessable')
    end

    it "should show list of Places" do
      Place.index
      visit places_path
      expect(page).to have_content @place.name
    end

#    it "should mark Places as reviewed" do
#      Place.index
#
#      expect(@place.reviewed).to be false
#
#      visit places_path
#      expect(page).to have_content @place.name
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
#      @place.reload
#      expect(@place.reviewed).to be true
#      expect(@place.reviewed_by_id).to eq(@admin.id)
#    end

  end

end
