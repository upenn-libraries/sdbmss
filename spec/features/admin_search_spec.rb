
require "rails_helper"

describe "Admin search", :js => true do

  before :all do
    SDBMSS::ReferenceData.create_all

    @unapproved_entry = Entry.new(
      source: Source.last,
      created_by: @user,
      folios: 15,
    )
    @unapproved_entry.save!

    SDBMSS::Util.wait_for_solr_to_be_current

    @user = User.create!(
      email: 'testuser@testadminsearch.com',
      username: 'testadminsearch',
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

  it "should return JSON results successfully", js: false do
    visit admin_search_path(format: :json)
    data = JSON.parse(page.source)
    expect(data['error']).to be_nil
  end

  it "should show table of entries" do
    visit admin_search_path
  end

  it "should search" do
    visit admin_search_path

    first("input[name='search_value']").native.send_keys "de ricci"
    click_button "Search"
    expect(page).not_to have_selector("#spinner", visible: true)

    expect(all("#search_results tbody tr").count).to eq(2)
  end

  it "should mark entry as approved" do

    visit admin_search_path
    first("#unapproved_only").click
    click_button "Search"

    expect(page).to have_selector("#select-all", visible: true)
    find("#select-all").click

    expect(page).to have_selector("#mark-as-approved")
    find("#mark-as-approved").click

    expect(page).to have_content("No records found")

    @unapproved_entry.reload
    expect(@unapproved_entry.approved).to be true
    expect(@unapproved_entry.approved_by_id).to eq(@user.id)
  end

end
