
require 'json'
require "rails_helper"

describe "Manage Names", :js => true do

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
    author = Name.author
    author.name = "Jane Doe"
    author.save!

    Name.index

    visit names_path
    expect(page).to have_content("Manage all name records")
    expect(page).to have_content(author.name)
  end

  it "should show merge link when new name already exists" do
    author = Name.author
    author.name = "Joe Schmoe"
    author.save!

    author2 = Name.author
    author2.name = "Another Joe Schmoe"
    author2.save!

    visit edit_name_path(author)
    fill_in 'name_name', :with => "Another Joe Schmoe"
    click_button 'Update Name'

    expect(page).to have_content("Click here to merge")
  end
end
