
require 'json'
require "rails_helper"
require 'net/http'

describe "User Activity", :js => true do

  before :each do
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
    find(".save-button", match: :first).trigger('click')
    sleep 1.1
#    puts Entry.find(10).entry_titles
    return old
  end

  it "should show appropriate recent activity" do
    v = doActivity(10)
    visit activities_path
    expect(page).to have_content('edited SDBM_10')
    expect(page).to have_content("Title changed from #{v} to Book of Ours")
  end

  it "should correctly display deleting a record associaton" do
    doActivity(10)
    visit edit_entry_path(10)
    sleep(1)
    find("#delete_title_0", match: :first).click
    expect(page).to have_content("Are you sure you want to remove this field and its contents?")
    click_button "Yes"    
    find(".save-button", match: :first).click
    sleep 1.1
    visit activities_path
    expect(page).to have_content('edited SDBM_10')
    expect(page).to have_content("Book of Ours")
  end

  it "should create a new name and show it in the activity", :known_failure do
    visit new_name_path
    fill_in 'name_name', with: 'Stacker Pentecost'
    find_by_id('name_is_artist').click
    click_link 'Save'
    expect(page).to have_content('Stacker Pentecost')
    visit activities_path
    expect(page).to have_content('added SDBM_NAME_')
    expect(page).to have_content('Name set to Stacker Pentecost')
  end

  it "should destroy a name record and show it in the activity" do
    name = Name.create!(name: 'Stacker Pentecost', is_artist: true, created_by: @user)
    Name.index
    SDBMSS::Util.wait_for_solr_to_be_current
    # to handle the confirm alert
    page.evaluate_script('window.confirm = function() { return true; }')

    visit names_path
    
    expect(page).to have_content("Delete")
    
    find("#delete_#{name.id}", match: :first).trigger('click')
    expect(page).to have_content("Are you sure you want to delete this record?")
    click_button "Yes"
    expect(page).not_to have_content('Stacker Pentecost')

    visit activities_path
    expect(page).to have_content('deleted SDBM_NAME')
  end

end
