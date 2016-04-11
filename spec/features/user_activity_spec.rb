
require 'json'
require "rails_helper"
require 'net/http'

describe "User Activity", :js => true do

  before :all do
    SDBMSS::ReferenceData.create_all

    User.where(username: 'testuser').delete_all
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'testuser',
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

  def doActivity()
    visit edit_entry_path(10)
    find_by_id('add_title').click
    old = find_field('title_0').value
    fill_in 'title_0', with: 'Book of Ours'
    first(".save-button").click

    visit activities_path
    expect(page).not_to have_content('updated SDBM_10')
    expect(page).not_to have_content("Title: from #{value} to Book of Ours")
  end

  it "should show empty user activity" do
    visit activities_path

    expect(page).not_to have_content('updated')
    expect(page).not_to have_content('created')
    expect(page).not_to have_content('destroyed')
  end

  it "should show appropriate recent activity" do
    doActivity()
    skip
  end

end