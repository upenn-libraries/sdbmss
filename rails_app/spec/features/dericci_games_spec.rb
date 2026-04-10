require "rails_helper"

describe "De Ricci Game", :js => true do
  let(:admin_user) { User.find_by(role: "admin") }

  def resolve_game_record(index)
    if index.zero?
      find(".selectName", match: :first).click
      return
    end

    find("#cantfindtoggle").click
    expect(page).to have_content("Not Sure")

    case index
    when 1
      find("#flag-add").click
    when 2
      find("#skip").click
    else
      find("#flag-scope").click
    end
  end

  context "when user is logged in " do
    before do
      login(admin_user, "somethingunguessable")
    end

    it "should load the dericci game landing page and start a new game" do
      visit dericci_games_path
      expect(page).to have_content("Start a New Game")

      find('#new-game').click
      expect(page).to have_content("Is there a problem with this .pdf file")
    end

    it "should allow you to continue a game previously started" do
      visit dericci_games_path
      find('#new-game').click

      visit dericci_games_path
      expect(page).to have_content("In Progress")
      find("[data-target='#in-progress']").click
      within("#in-progress") do
        first(".play-game").click
      end
      expect(page).to have_content('Select a Record and click')

      all(".game-nav li").each_with_index do |row, index|
        row.find('.view-name').click
        row.find('.find-name').click
        expect(page).to have_content("in SDBM Name Authority")
        expect(page).to have_content("Link")
        expect(page).not_to have_content("No results found")
        sleep 1
        resolve_game_record(index)
        expect(page).not_to have_content("in SDBM Name Authority")
      end
      first(".game-nav li").find('.view-name').click
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
