
require "rails_helper"

describe "Manage entries", :js => true do

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
    visit entries_path(format: :json)
    data = JSON.parse(page.source)
    expect(data['error']).to be_nil
  end

  it "should show table of entries" do
    visit entries_path
  end

  it "should search" do
    visit entries_path

    first("input[name='search_value']").native.send_keys "de ricci"
    find('#search_submit').click()
    sleep 1.1
    expect(page).not_to have_selector("#spinner", visible: true)

    expect(all("#search_results tbody tr").count).to eq(1)
  end

  it "should jump to ID" do
    skip
    # jump to removed for being irrelevant...
    visit entries_path

    fill_in 'jump_to', :with => "10"
    click_button "Go"
    expect(page).not_to have_selector("#spinner", visible: true)

    expect(all("#search_results tbody tr").count).to eq(Entry.all.count)
  end

  it "should delete an entry" do
    count = Entry.all.count

    # mock out the confirm dialogue
    page.evaluate_script('window.confirm = function() { return true; }')

    visit entries_path
    all(".entry-delete-link").last.click
    sleep(1)

    expect(Entry.all.count).to eq(count - 1)
  end

  it "should mark entry as approved" do

    visit entries_path
    first("#unapproved_only").click
    find('#search_submit').click()

    sleep 1.1

    expect(page).to have_selector("#select-all", visible: true)
    first("#select-all").click

    expect(page).to have_selector("#mark-as-approved")
    find("#mark-as-approved").click

    expect(page).to have_content("No records found")

    @unapproved_entry.reload
    expect(@unapproved_entry.approved).to be true
    expect(@unapproved_entry.approved_by_id).to eq(@user.id)
  end

  it "should mark entry as deprecated" do

    expect(Entry.where(deprecated: true).count).to be(0)

    visit entries_path
    first(".entry-deprecate-link").click

    superceded_by_id = Entry.first.id
    fill_in 'superceded_by_id', :with => superceded_by_id
    find("#deprecate").click
    sleep(1)
    expect(page).to have_content("Entry marked as deprecated.")

    entry = Entry.find_by(deprecated: true)
    expect(entry.superceded_by_id).to be(superceded_by_id)
  end

  it "should load all entries from the Manage Entries page" do
    visit entries_path

    expect(page.find('#search_results_info')).to have_content(ActiveSupport::NumberHelper::number_to_delimited(Entry.all.count))
  end

  it "should perform a search on any field without error" do
    visit entries_path

    expect(page.first("select[name='search_field']").all("option").length).to eq(42)

    40.times do |i|
      page.first("input[name='search_value']").set "Test String"
      option = page.first("select[name='search_field']").all("option")[i]
      option.select_option
      find('#search_submit').click()
      # puts "Option: #{option.value}, success"
    end
  end

  it "should perform a search with multiple values for the same field (AND)" do
    visit entries_path

    find('#addSearch').click()

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Augustine"
    searchOptions[0].set "Author"

    textInputs[1].set "Hippo"
    searchOptions[1].set "Author"

    find('#search_submit').click()

    sleep 2

    count = page.find('#search_results_info').text.match(/of\s([\d,]+)\s/)[1].gsub(",", "").to_i

    visit entries_path

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Augustine AND Hippo"
    searchOptions[0].set "Author"

    find('#search_submit').click()

    sleep 2

    count2 = page.find('#search_results_info').text.match(/of\s([\d,]+)\s/)[1].gsub(",", "").to_i

    expect(count).to eq(count2)
  end

  it "should perform a search with multiple values for the same field (ANY)" do
    visit entries_path

    find('#addSearch').click()

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Augustine"
    searchOptions[0].set "Author"

    textInputs[1].set "Cicero"
    searchOptions[1].set "Author"

    select 'Any', from: 'op'

    find('#search_submit').click()

    sleep 2

    count = page.find('#search_results_info').text.match(/of\s([\d,]+)\s/)[1].gsub(",", "").to_i

    visit entries_path

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Augustine OR Cicero"
    searchOptions[0].set "Author"

    find('#search_submit').click()

    sleep 2

    count2 = page.find('#search_results_info').text.match(/of\s([\d,]+)\s/)[1].gsub(",", "").to_i

    expect(count).to eq(count2)
  end

end
