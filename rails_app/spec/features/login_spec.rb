
require "rails_helper"

describe "Login", :js => true do

  let(:password) { "somethingunguessable" }
  let(:active_user) { User.where(role: "contributor").first }
  let(:admin_user) { User.where(role: "admin").first }
  let(:inactive_user) do
    User.find_or_initialize_by(username: "user_inactive").tap do |user|
      user.email = "user2@logintest.com"
      user.active = false
      user.password = password unless user.persisted?
      user.save!
    end
  end

  before :each do
    inactive_user
  end

  it "should allow login" do
    login(active_user, password)
  end

  it "should disallow login" do
    visit root_path

    fill_in "user_login", with: inactive_user.username
    fill_in "user_password", with: password
    click_button 'Log in'

    expect(page).to have_content "New SDBM accounts are inactive by default."
  end

  it "should allow login_as" do
    login(admin_user, password)
    visit login_as_path username: active_user.username
    expect(page.status_code).to eq(200)
  end

  it "should disallow login_as" do
    login(active_user, password)

    visit login_as_path username: admin_user.username
    expect(page.status_code).to eq(403)
  end

end
