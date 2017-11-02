
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

    game = DericciGame.last

    15.times do |i|
      within "ul.game-nav li:nth-child(#{i + 1})" do
        #find(".btn-default").click
        find(".btn-primary").click
      end
      expect(page).to have_content("Find '#{game.dericci_records[i].name}' in SDBM Name Authority")
      if i < 5
        if all(".selectName").count > 0
          first(".selectName").click
        else
          find('#cantfindtoggle').click
          expect(page).to have_content("Not Sure")
          click_link "Not Sure"  
        end
      elsif i < 10
        find('#cantfindtoggle').click
        expect(page).to have_content("Not Sure")
        click_button "Yes"
      else
        find('#cantfindtoggle').click
        expect(page).to have_content("Not Sure")
        click_button "No"
      end
    end

    click_link 'Submit'
    expect(page).to have_content("Thank you for playing the Dericci Archives Game!")
  end

end