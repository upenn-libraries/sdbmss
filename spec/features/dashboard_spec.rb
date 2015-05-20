
require "rails_helper"

describe "Dashboard", :js => true do

  context "when regular user is logged in " do
    before :all do
      @user = User.create!(
        email: 'testuser@testdashboard.com',
        username: 'testdashboard',
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

    it "should show dashboard page" do
      visit dashboard_path
    end

  end

  context "when admin user is logged in " do
    before :all do
      @admin_user = User.create!(
        email: 'testadminuser@testdashboard.com',
        username: 'testdashboardadmin',
        password: 'somethingunguessable',
        role: 'admin',
      )
    end

    before :each do
      visit new_user_session_path
      fill_in 'user_login', :with => @admin_user.username
      fill_in 'user_password', :with => 'somethingunguessable'
      click_button 'Log in'
      expect(page).to have_content 'Signed in successfully'
    end

    it "should show dashboard page" do
      visit dashboard_path
    end
  end

end
