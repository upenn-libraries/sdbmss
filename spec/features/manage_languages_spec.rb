
require "rails_helper"

describe "Manage languages", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@testlanguage.com',
      username: 'languagetestuser',
      password: 'somethingunguessable'
    )
    @language = Language.create!(
      name: "Martian"
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

  xit "should show list of Languages" do
    visit languages_path
    expect(page).to have_content @language.name
  end

  it "should add a new Language" do
    expect(Language.where(name: "Klingon").count).to eq(0)
    visit new_language_path
    fill_in "language_name", with: "Klingon"
    click_button "Create Language"
    expect(Language.where(name: "Klingon").count).to eq(1)
  end

  it "should delete a Language"

end
