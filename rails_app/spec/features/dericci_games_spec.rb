require "rails_helper"

describe "De Ricci Game", :js => true do
  let(:admin_user) { create(:admin) }

  def create_game_record(name)
    matching_name = Name.create!(
      name: name,
      is_author: true,
      created_by: admin_user
    )
    record = DericciRecord.create!(
      name: name,
      url: "about:blank",
      cards: 2,
      size: "<1 MB",
      place: "London, England.",
      dates: "(1795-1874)",
      senate_house: "[Senate House MS901/3/11]",
      created_by: admin_user,
      updated_by: admin_user
    )

    [record, matching_name]
  end

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
      login(admin_user, "somethingreallylong")
    end

    it "should load the dericci game landing page and start a new game" do
      visit dericci_games_path
      expect(page).to have_content("Start a New Game")

      find('#new-game').click
      expect(page).to have_content("Is there a problem with this .pdf file")
    end

    it "should allow you to continue a game previously started", :flaky, :solr do
      DericciRecord.update_all(out_of_scope: true)

      records, names = [
        "Zetland (Earl of) the 1st",
        "Zetland (Earl of) the 4st",
        "Zetland (Earl of) the 0st",
        "Zetland (Earl of) the 3st"
      ].map { |name| create_game_record(name) }.transpose

      records.each { |record| record.update!(out_of_scope: false) }
      SampleIndexer.index_records!(*names)

      visit dericci_games_path
      find('#new-game').click

      visit dericci_games_path
      expect(page).to have_content("In Progress")
      find("[data-bs-target='#in-progress']").click
      within("#in-progress") do
        first(".play-game").click
      end
      expect(page).to have_content('Select a Record and click')

      all(".game-nav li").each_with_index do |row, index|
        row.find('.view-name').click
        row.find('.find-name').click
        expect(page).to have_content("in SDBM Name Authority")
        expect(page).to have_css(".selectName", text: "Link")
        expect(page).not_to have_content("No results found")
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
