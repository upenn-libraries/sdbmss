
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
      login(@user, 'somethingunguessable')
  end

  it "should load" do
    visit manuscripts_path
    expect(page).to have_content("Manage Manuscript Records")
  end

  it "should load public view" do
    visit manuscript_path(Manuscript.last)
    expect(page).to have_content(Manuscript.last.public_id)
    Manuscript.last.entries.each do |entry|
      expect(page).to have_content(entry.public_id)
    end

    visit table_manuscript_path(Manuscript.last)
    expect(page).to have_content(Manuscript.last.public_id)
    Manuscript.last.entries.each do |entry|
      expect(page).to have_content(entry.public_id)
    end

  end

end
