
require "rails_helper"

describe "Manage sources", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@testlanguage.com',
      username: 'languagetestuser',
      password: 'somethingunguessable'
    )
    @source = Source.create!(
      source_type: Source::TYPE_AUCTION_CATALOG,
      title: "my test source"
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

  it "should show list of Sources" do
    visit sources_path
    expect(page).to have_content @source.title
  end

  it "should delete a Source"

end
