
require "rails_helper"

describe "Data entry", :js => true do

  before :all do
    User.where(username: 'testuser').delete_all
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'testuser',
      password: 'somethingunguessable'
    )
  end

  before :each do
    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  it "should load New Entry page correctly with an auction catalog Source" do
    source = Source.new(
      title: "xxx",
      source_type: Source::TYPE_AUCTION_CATALOG
    )
    source.save!

    visit new_entry_path :source_id => source.id

    expect(page).to have_content 'Add an Entry - Fill out details'

    expect(page).to have_content 'Transaction Information'

    # TODO: save it and make sure there IS a transaction

  end

  it "should load New Entry page correctly with a institutional catalog Source" do
    source = Source.new(
      title: "xxx",
      source_type: Source::TYPE_COLLECTION_CATALOG
    )
    source.save!

    visit new_entry_path :source_id => source.id

    expect(page).to have_content 'Add an Entry - Fill out details'

    expect(page).to have_no_content 'Transaction Information'

    # TODO: save it and make sure there's no transaction

  end

  it "should save a Source correctly"

  it "should save an Entry correctly"

  it "should disallow creating Entries if not logged in"

  it "should validate when saving Entry"

end
