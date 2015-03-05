
require "rails_helper"

describe "Admin search", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@testadminsearch.com',
      username: 'testadminsearch',
      password: 'somethingunguessable'
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

  xit "should show table of entries" do
    visit admin_search_path
  end

end
