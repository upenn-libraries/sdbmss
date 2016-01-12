
require 'json'
require "rails_helper"

describe "Manage Names", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'adminuser',
      password: 'somethingunguessable',
      role: 'admin'
    )
  end

  before :each do
    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  after :each do
    page.reset!
  end

  it "should show merge options when selecting 'merge' from name list" do
    author = Name.author
    author.name = "John Milton"
    author.save!

    author2 = Name.author
    author2.name = "Milton, John"
    author2.save!

    visit names_path
    expect(page).to have_content("Merge")

    #select most recently created author (author2) to MERGE
    first('.merge-link').click

    expect(page).to have_content("Merge")
    expect(page).to have_content(author2.id)

    fill_in "target_id", :with => author.id
    click_button "Show"

    #MERGE TO author (John Milton)
    expect(page).to have_content(author.name)
    click_button "Yes"

    #Success message
    expect(page).to have_content("Successfully merged")

    #author2 should no longer appear in NAME LIST
    visit names_path
    expect(page).to have_no_content(author2.name)
  end
end