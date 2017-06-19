
require 'json'
require "rails_helper"

describe "Browse Dericci Records", :js => true do

  before :all do
    @user = User.where(role: "admin").first
    @user2 = User.where(role: "contributor").first

    15.times do |i|
      DericciRecord.create(name: "Georges Danton", place: "Paris", dates: "1794 (#{i})", senate_house: "[Senate House MS901/3/11]")
    end

    Name.create(name: "Camillo", is_author: true)
    Name.create(name: "George Danton Mssr", is_author: true)
  end

  before :each do
    login(@user, 'somethingunguessable')
  end

  after :each do
    page.reset!
  end

  it "should create a new game" do
    visit dericci_games_path
    click_link "Start a New Game"
    expect(page).to have_content("Instructions")

    15.times do |i|
      within "ul.game-nav li:nth-child(#{i + 1})" do
        find(".btn-default").click
        find(".btn-primary").click
      end
      expect(page).to have_content("George Danton Mssr")
      if i < 5
        first(".selectName").click
      elsif i < 10
        click_button "Yes"
      else
        click_button "Not Sure"
      end
    end

    click_link 'Submit'
    sleep 1
    expect(page).not_to have_content("Linked")
  end

end