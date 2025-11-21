
require 'json'
require "system_helper"

#ActiveRecord::Base.logger = Logger.new(STDOUT) if defined?(ActiveRecord::Base)

describe "Manage Merging Sources", :js => true do

  before :all do
    @user = User.where(role: "admin").first

#    SDBMSS::ReferenceData.create_all
  end

  before :each do
      login(@user, 'somethingunguessable')
  end

  after :each do
    page.reset!
  end

  def create_sources
    ct = Entry.count

    @source = Source.new(
      title: "The Book Repository",
      source_type: SourceType.auction_catalog,
      source_agents_attributes: [
        {
          agent: Name.find_or_create_agent("The Milkman"),
          role: SourceAgent::ROLE_SELLING_AGENT,
        }
      ]
    )
    @source.save!

    @source2 = Source.new(
      title: "The Milkman Conspiracy",
      source_type: SourceType.auction_catalog,
      source_agents_attributes: [
        {
          agent: Name.find_or_create_agent("Milkman, The"),
          role: SourceAgent::ROLE_SELLING_AGENT,
        }
      ]
    )
    @source2.save!

    visit new_entry_path :source_id => @source.id
    fill_in 'folios', with: '7'
    first(".save-button").click
    
    expect(page).to have_content('Warning: This entry has not been approved yet. The data may be incorrect or unreliable, or may not conform to the general data standards.')
    #sleep 1.1

    visit new_entry_path :source_id => @source2.id

    find_by_id('add_title').click
    fill_in 'title_0', with: 'Test Title'
    first(".save-button").click

    expect(page).to have_content('Warning: This entry has not been approved yet. The data may be incorrect or unreliable, or may not conform to the general data standards.')

    expect(Entry.count).to eq(ct + 2)
  end

  it "should successfully merge two sources together, combining all their entries" do
    create_sources
    
    c1 = Entry.where(source_id: @source.id).count
    c2 = Entry.where(source_id: @source2.id).count

    visit merge_source_path(@source)

    fill_in 'target_id', with: @source2.id
    click_button 'select-specific'

    expect(page).to have_content("Merge #{@source.public_id}")
    expect(page).to have_content("#{@source2.public_id}")

    click_button("Yes")
    
    expect(page).to have_content("#{@source.public_id} has been successfully merged into #{@source2.public_id}")

    @source2.index!
    @source2.entries.each do |e|
      e.index!
    end

    @source2 = Source.find(@source2.id)

    # counters don't work in specs?

    visit source_path(@source2)
    expect(page).to have_content(@source2.public_id)
    expect(@source2.entries_count).to eq(Entry.where(source_id: @source2.id).count)
  end

end
