
require 'json'
require "rails_helper"

describe "Manage Names", :js => true do

  before :all do
    @user = User.where(role: "admin").first

  end

  before :each do
      login(@user, 'somethingunguessable')
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
    expect(page).to have_content("Manage Names")
    expect(page).to have_content(author.name)
  end

  it "should show merge link when new name already exists" do
    author = Name.author
    author.name = "Joe Zchmoe"
    author.save!

    author2 = Name.author
    author2.name = "Another Joe Schmoe"
    author2.save!

    Name.index

    visit edit_name_path(author)
    fill_in 'name_name', :with => "Another Joe Schmoe"
    click_button 'Update Name'

    expect(page).to have_content("Click here to merge")
  end

  it "should show suggestions for names to merge into" do
    expect(Name.last.name).to eq("Another Joe Schmoe")

    visit merge_name_path(Name.last.id)

    expect(page).to have_content(Name.last.name)

    expect(page).to have_content(Name.last(2)[0].name)
  end
end
