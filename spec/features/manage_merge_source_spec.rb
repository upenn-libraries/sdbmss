
require 'json'
require "rails_helper"

describe "Manage Merging Sources", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'adminuser',
      password: 'somethingunguessable',
      role: 'admin'
    )
    SDBMSS::ReferenceData.create_all
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

  it "should successfully merge two sources together, combining all their entries" do
    source = Source.new(
      title: "The Book Repository",
      source_type: SourceType.auction_catalog,
      source_agents_attributes: [
        {
          agent: Name.find_or_create_agent("The Milkman"),
          role: SourceAgent::ROLE_SELLING_AGENT,
        }
      ]
    )
    source.save!

    source2 = Source.new(
      title: "The Milkman Conspiracy",
      source_type: SourceType.auction_catalog,
      source_agents_attributes: [
        {
          agent: Name.find_or_create_agent("Milkman, The"),
          role: SourceAgent::ROLE_SELLING_AGENT,
        }
      ]
    )
    source2.save!

    visit new_entry_path :source_id => source.id

    fill_in 'folios', with: '7'

    first(".save-button").click
  end

end
