
require "rails_helper"

describe "Login", :js => true do

  before :all do
    @user_active = User.create!(
      email: 'user1@logintest.com',
      username: 'user_active',
      password: 'somethingunguessable'
    )

    @user_inactive = User.create!(
      email: 'user2@logintest.com',
      username: 'user_inactive',
      password: 'somethingunguessable',
      active: false
    )

    @admin = User.create!(
      email: 'admin@logintest.com',
      username: 'admin',
      password: 'somethingunguessable',
      role: 'admin'
    )
  end

  it "should allow login" do
    visit root_path
    fill_in 'user_login', :with => @user_active.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  it "should disallow login" do
    visit root_path
    fill_in 'user_login', :with => @user_inactive.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Your account has been de-activated.'
  end

  it "should allow login_as" do
    visit root_path
    fill_in 'user_login', :with => @admin.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'

    visit login_as_path username: @user_active.username
    expect(page.status_code).to eq(200)
  end

  it "should disallow login_as" do
    visit root_path
    fill_in 'user_login', :with => @user_active.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'

    visit login_as_path username: @admin.username
    expect(page.status_code).to eq(403)
  end

end
