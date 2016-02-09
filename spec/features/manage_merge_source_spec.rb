
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

  def create_sources
    ct = Entry.count

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
    
    sleep 1.1

    visit new_entry_path :source_id => source2.id

    find_by_id('add_title').click
    fill_in 'title_0', with: 'Test Title'
    first(".save-button").click

    sleep 1.1

    expect(Entry.count).to eq(ct + 2)
  end

# for some reason the indexes are not updating fast enough, or at all?

  it "should successfully merge two sources together, combining all their entries" do
    create_sources
    source = Source.last
    source2 = Source.last(2)[1]

    c1 = Entry.where(source_id: source.id).count
    c2 = Entry.where(source_id: source2.id).count

    source.merge_into(source2)

    expect(source.deleted).to be_truthy

    expect(source2.entries_count).to eq(Entry.where(source_id: source2.id).count)
  end

end
