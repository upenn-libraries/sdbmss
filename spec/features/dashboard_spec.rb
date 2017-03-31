
require "rails_helper"

describe "Dashboard", :js => true do

  context "when regular user is logged in " do
    before :all do
      @user = User.where(role: "contributor").first
=begin
      User.create!(
        email: 'testuser@testdashboard.com',
        username: 'testdashboard',
        password: 'somethingunguessable'
      )
=end      
    end

    before :each do
      visit root_path
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
      @admin_user = User.where(role: "admin").first
    end

    before :each do
      visit root_path
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
