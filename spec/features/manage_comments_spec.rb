
require "rails_helper"

describe "Manage entries", :js => true do

  before :all do
    SDBMSS::ReferenceData.create_all

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

  it "should show manage comments page" do
    visit comments_path
  end

end
