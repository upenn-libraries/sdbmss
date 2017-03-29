
require "rails_helper"

describe "Manage manuscripts", :js => true do

  before :all do
    @user = User.where(role: "admin").first

    @source = Source.create!(
      source_type: SourceType.auction_catalog,
      title: "my test source"
    )
  end

  before :each do
    visit root_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  it "should load" do
    visit manuscripts_path
    expect(page).to have_content("Manage Manuscript Records")
  end

end
