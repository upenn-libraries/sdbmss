require 'json'
require "rails_helper"
require 'net/http'

describe "Date Entry Workflow", :js => true do

  before :all do
    # since we already have a set of reference data, we use that here
    # instead of creating another set of test data. The consequence is
    # that these tests don't exercise everything as thoroughly as they
    # should, but they're probably good enough.

    SDBMSS::ReferenceData.create_all

    SDBMSS::Util.wait_for_solr_to_be_current

    @user = User.create!(
      email: 'search@search.com',
      username: 'search',
      password: 'somethingunguessable',
    )
    @user.role = 'admin'
    @user.save!
  end

  before :each do
    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  it "should update 'Date For Search' with parsed DATE information on change to 'Date As Recorded'" do
    visit edit_entry_path :id => 13

    expect(page).to have_content("Edit entry")

    find_by_id('add_date').click
    fill_in "date_observed_date_0", with: "XVth century"
    find_by_id('date_normalized_start_0').click

    expect(find('#date_normalized_start_0').value).to eq('1400')
    expect(find('#date_normalized_end_0').value).to eq('1501')
  end

  it "should NOT update 'Date For Search' with parsed DATE on BLUR or FOCUS events without any change" do
    visit edit_entry_path :id => 13

    expect(page).to have_content("Edit entry")

    find_by_id('add_date').click
    start_date = find('#date_normalized_start_0').value
    end_date = find('#date_normalized_end_0').value

    recorded_date = find('#date_observed_date_0').value

    # update ACTUAL date field
    find_by_id('add_date').click

    fill_in "date_normalized_start_0", with: 1234

    find('#date_observed_date_0').click()
    find('#date_normalized_start_0').click()

    # normalized start date should still be what we changed it to
    expect(find('#date_normalized_start_0').value).to eq('1234')
  end

end