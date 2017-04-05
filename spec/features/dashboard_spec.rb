
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
      login(@user, 'somethingunguessable')
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
      login(@admin_user, 'somethingunguessable')
    end

    it "should show dashboard page" do
      visit dashboard_path
    end
  end

end
