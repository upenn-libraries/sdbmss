require "rails_helper"

describe "De Ricci Game", :js => true do
  context "when user is logged in " do
    before :all do
      @admin_user = User.where(role: "admin").first
    end

    before :each do
      login(@admin_user, 'somethingunguessable')
    end

    it "should load the dericci game landing page and start a new game" do
      visit dericci_games_path
      expect(page).to have_content("Start a New Game")
      
      find('#new-game').click
      expect(page).to have_content("Is there a problem with this .pdf file")
    end

    it "should allow you to continue a game previously started" do
      visit dericci_games_path
      expect(page).to have_content("My Games")
      find("#open-games").click
      first('.play-game').click
      expect(page).to have_content('Select a Record and click')

      views = all('.view-name')
      all('.find-name').each_with_index  do |n, index|
        views[index].click
        n.click
        expect(page).to have_content("in SDBM Name Authority")
        expect(page).to have_content("Link")
        expect(page).not_to have_content("No results found")
        sleep 1
        if index < 1
          first(".selectName").click
        elsif index < 2
          click_link "cantfindtoggle"
          expect(page).to have_content("Not Sure")
          find('#flag-add').click
        elsif index < 3
          click_link "cantfindtoggle"
          expect(page).to have_content("Not Sure")
          find('#skip').click
        else          
          click_link "cantfindtoggle"
          expect(page).to have_content("Not Sure")
          find('#flag-scope').click
        end        
        expect(page).not_to have_content("in SDBM Name Authority")
      end
      views[0].click
      expect(page).to have_content("SDBM_NAME_")
      fill_in 'other-info', with: 'Some other things to consider are...'
      fill_in 'comment', with: 'This is a very interesting card!!!'
      find('#save-game').click
      expect(page).to have_content("Thank you for playing the Dericci Archives Game!")
    end
  end

  it "should require the user to be logged in" do
    page.reset!
    visit dericci_games_path
    expect(page).to have_content("Welcome to the De Ricci Digitized Archive Name Game! You must create an account or log in to play")
  end

end