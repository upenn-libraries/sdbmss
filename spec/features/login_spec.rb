
require "rails_helper"

describe "Login", :js => true do

  before :all do
    @user_active = User.where(role: "contributor").first

    @user_inactive = User.create!(
      email: 'user2@logintest.com',
      username: 'user_inactive',
      password: 'somethingunguessable',
      active: false
    )

    @admin = User.where(role: "admin").first
  end

  it "should allow login" do
    login(@user_active, 'somethingunguessable')
  end

  it "should disallow login" do
    login(@user_inactive, 'somethingunguessable')
  end

  it "should allow login_as" do
    login(@admin, 'somethingunguessable')
    visit login_as_path username: @user_active.username
    expect(page.status_code).to eq(200)
  end

  it "should disallow login_as" do
    login(@user_active, 'somethingunguessable')

    visit login_as_path username: @admin.username
    expect(page.status_code).to eq(403)
  end

end
