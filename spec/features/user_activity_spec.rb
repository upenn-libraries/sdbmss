
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

  def doActivity(id)
    visit edit_entry_path(id)
    find_by_id('add_title').click
    old = find_field('title_0').value
#    puts old
    fill_in 'title_0', with: 'Book of Ours'

    nw = find_field('title_0').value
#    puts nw
    first(".save-button").click
    sleep 1.1
#    puts Entry.find(10).entry_titles
    return old
  end

  it "should show empty user activity" do
    visit activities_path

    expect(page).not_to have_content('edited')
    expect(page).not_to have_content('added')
    expect(page).not_to have_content('deleted')
  end

  it "should show appropriate recent activity" do
    v = doActivity(10)
    visit activities_path
    expect(page).to have_content('edited SDBM_10')
    expect(page).to have_content("Title changed from #{v} to Book of Ours")
  end

  it "should correctly display deleting a record associaton" do
    visit edit_entry_path(10)
    sleep(1)
    first("#delete_title_0").click
    first(".save-button").click
    sleep 1.1
    visit activities_path
    expect(page).to have_content('edited SDBM_10')
    expect(page).to have_content("Title Book of Ours")
  end

  it "should create a new name and show it in the activity" do
    visit new_name_path
    fill_in 'name_name', with: 'Stacker Pentecost'
    find_by_id('name_is_artist').click
    click_button 'Create Name'
    expect(page).to have_content('Stacker Pentecost')
    visit activities_path
    expect(page).to have_content('added SDBM_NAME_')
    expect(page).to have_content('Name set to Stacker Pentecost')
  end

  it "should destroy a name record and show it in the activity" do
    # to handle the confirm alert
    page.evaluate_script('window.confirm = function() { return true; }')

    visit names_path
    first(".delete-link").click
    sleep 1.1
    expect(page).not_to have_content('Stacker Pentecost')

    visit activities_path
    expect(page).to have_content('deleted SDBM_NAME')
  end

end