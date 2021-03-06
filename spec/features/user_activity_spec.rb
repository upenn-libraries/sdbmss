
require 'json'
require "rails_helper"
require 'net/http'

describe "User Activity", :js => true do

  before :all do
#    SDBMSS::ReferenceData.create_all
    @user = User.where(role: "admin").first

  end

  before :each do
      login(@user, 'somethingunguessable')
  end

  def doActivity(id)
    visit edit_entry_path(id)
    find_by_id('add_title').click
    old = find_field('title_0').value
#    puts old
    fill_in 'title_0', with: 'Book of Ours'

    nw = find_field('title_0').value
#    puts nw
    first(".save-button").trigger('click')
    sleep 1.1
#    puts Entry.find(10).entry_titles
    return old
  end

  it "should show empty user activity" do
    skip "no such thing as empty user activity, since reference data persists for all tests"
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
    expect(page).to have_content("Are you sure you want to remove this field and its contents?")
    click_button "Yes"    
    first(".save-button").click
    sleep 1.1
    visit activities_path
    expect(page).to have_content('edited SDBM_10')
    expect(page).to have_content("Book of Ours")
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
    
    expect(page).to have_content("Delete")
    
    first("#delete_#{Name.last.id}").trigger('click')
    expect(page).to have_content("Are you sure you want to delete this record?")
    click_button "Yes"
    expect(page).not_to have_content('Stacker Pentecost')

    visit activities_path
    expect(page).to have_content('deleted SDBM_NAME')
  end

end