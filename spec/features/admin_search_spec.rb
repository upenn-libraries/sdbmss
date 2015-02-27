
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
    page.driver.resize_window(1024, 768)

    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  xit "should show table of entries" do
    visit admin_search_path
  end

end
