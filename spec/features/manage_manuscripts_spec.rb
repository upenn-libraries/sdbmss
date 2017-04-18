
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

end
