
require "rails_helper"
describe "Manage places", :js => true do
  let(:admin_user) { create(:admin) }

  before :each do
    @admin = admin_user
    @user = admin_user
  end

  context "when contributor is logged in" do

    before :each do
      @place = Place.create!(
        name: "Martian",
        created_by: @user,
      )
      fast_login(@user)
    end

    it "should add a new Place" do
      expect(Place.where(name: "Klingon").count).to eq(0)
      visit new_place_path
      fill_in "place_name", with: "Klingon"
      click_link "Save New Place"

      expect(page).to have_content("This place is not directly used")

      expect(Place.where(name: "Klingon").count).to eq(1)
      place = Place.where(name: "Klingon").first
      expect(place.reviewed).to eq(false)
    end

    it "should edit a Place" do
      place = Place.create(name: "Already reviewed", reviewed: true, created_by: @user)

      visit edit_place_path :id => place.id
      fill_in "place_name", with: "This should change to unreviewed"
      click_link "Save #{place.public_id}"
      expect(page).to have_content("This place is not directly used")

      place = Place.find(place.id)
    end

    it "should delete a Place" do
      # this is a very rough test!
      skip "contributors can't delete places."
      count = Place.count

      # mock out the confirm dialogue
      page.evaluate_script('window.confirm = function() { return true; }')

      visit places_path
      find(".delete-link", match: :first).click
      sleep(1)

      expect(Place.count).to eq(count-1)
    end

    it "should export CSV", :js => false,
      skip: "place CSV export still exists, but async download polling belongs in lower-level coverage instead of this feature spec" do
    end
  end

  context "when admin is logged in" do

    before :each do
      @place = Place.create!(
        name: "Pig Latin",
        created_by: @user,
      )
      fast_login(@admin)
    end

#    it "should mark Places as reviewed" do
#      Place.index
#
#      expect(@place.reviewed).to be false
#
#      visit places_path
#      expect(page).to have_content @place.name
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
#      @place.reload
#      expect(@place.reviewed).to be true
#      expect(@place.reviewed_by_id).to eq(@admin.id)
#    end

  end

end
