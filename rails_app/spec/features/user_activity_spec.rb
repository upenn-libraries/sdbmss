require "rails_helper"

describe "User Activity", :js => true do
  let(:admin_user) { User.where(role: "admin").first }
  let(:entry_id) { 10 }

  before :each do
    login(admin_user, 'somethingunguessable')
  end

  def perform_activity(id)
    visit edit_entry_path(id)
    find_by_id('add_title').click
    original_title = find_field('title_0').value
    fill_in 'title_0', with: 'Book of Ours'

    find(".save-button", match: :first).trigger('click')
    sleep 1.1
    original_title
  end

  it "should show appropriate recent activity" do
    original_title = perform_activity(entry_id)
    visit activities_path
    expect(page).to have_content('edited SDBM_10')
    expect(page).to have_content("Title changed from #{original_title} to Book of Ours")
  end

  it "should correctly display deleting a record associaton" do
    perform_activity(entry_id)
    visit edit_entry_path(entry_id)
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

  it "should create a new name and show it in the activity" do
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
    name = Name.create!(name: 'Stacker Pentecost', is_artist: true, created_by: admin_user)
    Name.index
    SDBMSS::Util.wait_for_solr_to_be_current

    visit names_path
    
    expect(page).to have_content("Delete")
    
    accept_confirm_from do
      find("#delete_#{name.id}", match: :first).trigger('click')
    end
    expect(page).to have_content("Are you sure you want to delete this record?")
    click_button "Yes"
    expect(page).not_to have_content('Stacker Pentecost')

    visit activities_path
    expect(page).to have_content('deleted SDBM_NAME')
  end

end
