
require "rails_helper"

describe "Login", :js => true do

  before :each do
    @user_active = User.where(role: "contributor").first

    @user_inactive = User.find_or_initialize_by(username: 'user_inactive')
    @user_inactive.email = 'user2@logintest.com'
    @user_inactive.active = false
    @user_inactive.password = 'somethingunguessable' unless @user_inactive.persisted?
    @user_inactive.save!

    @admin = User.where(role: "admin").first
  end

  it "should allow login" do
    login(@user_active, 'somethingunguessable')
  end

  it "should disallow login" do
    visit root_path
    #find('#dismiss-welcome').click
    fill_in 'user_login', :with => @user_inactive.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'New SDBM accounts are inactive by default.'
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
