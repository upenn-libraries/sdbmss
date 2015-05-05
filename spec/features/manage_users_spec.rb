
require 'json'
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Manage Users", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'adminuser',
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

  after :each do
    page.reset!
  end

  it "should load" do
    visit accounts_path
    expect(page).to have_content("Manage all account records")
  end

  it "should create a user" do
    visit new_account_path
    expect(page).to have_content("New Account")

    fill_in 'user_username', with: "brandnewuser"
    fill_in 'user_email', with: "brandnewuser@upenn.edu"
    check 'user_email_is_public'
    fill_in 'user_password', with: "12345678"
    fill_in 'user_password_confirmation', with: "12345678"
    fill_in 'user_bio', with: "Some dude"
    click_button "Create User"

    u = User.find_by(username: "brandnewuser")
    expect(u.email).to eq("brandnewuser@upenn.edu")
    expect(u.email_is_public).to eq(true)
    expect(u.bio).to eq("Some dude")
    expect(u.role).to eq("contributor")
    expect(u.valid_password?("12345678")).to eq(true)
  end

  it "should change a user's password" do
    user = User.create!(
      email: 'testuser2@test.com',
      username: 'anotheruser',
      password: 'somethingunguessable',
      role: 'contributor'
    )

    visit edit_account_path(user)
    expect(page).to have_content("Editing User")

    fill_in 'user_password', with: "66666666"
    fill_in 'user_password_confirmation', with: "66666666"
    click_button "Update User"

    user.reload

    expect(user.valid_password?("66666666")).to eq(true)
  end

  it "should change a user's info" do
    user = User.create!(
      email: 'testuser3@test.com',
      username: 'yetanotheruser',
      password: 'somethingunguessable',
      role: 'contributor'
    )

    visit edit_account_path(user)
    expect(page).to have_content("Editing User")

    fill_in 'user_bio', with: "A changed bio"
    select 'editor', from: 'user_role'
    click_button "Update User"

    user.reload

    expect(user.bio).to eq("A changed bio")
    expect(user.role).to eq("editor")
    # check that password is NOT changed
    expect(user.valid_password?("somethingunguessable")).to eq(true)
  end

end
