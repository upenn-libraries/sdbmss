
require "rails_helper"

describe "Manage sources", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@testlanguage.com',
      username: 'languagetestuser',
      password: 'somethingunguessable'
    )
    @source = Source.create!(
      source_type: SourceType.auction_catalog,
      title: "my test source",
      created_by: @user,
    )
  end

  before :each do
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

  it "should delete a Source" do
    # this is a very rough test!
    count = Source.count

    # mock out the confirm dialogue
    page.evaluate_script('window.confirm = function() { return true; }')

    visit sources_path
    first(".source-delete-link").click
    sleep(1)

    expect(Source.count).to eq(count-1)
  end

end
