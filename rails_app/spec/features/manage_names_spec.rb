
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

  it "should show the merge page for an existing duplicate name" do
    author = Name.author
    author.name = "Joe Zchmoe"
    author.save!

    author2 = Name.author
    author2.name = "Another Joe Schmoe"
    author2.save!

    Name.index
    visit merge_name_path(author.id)

    expect(page).to have_content(author.name)
    expect(page).to have_content(author2.name)
  end

  it "should show suggestions for names to merge into" do
    name1 = Name.create!(name: 'Joe Schmoe', is_author: true, created_by: @user)
    name2 = Name.create!(name: 'Another Joe Schmoe', is_author: true, created_by: @user)
    Name.index
    expect(name2.name).to eq("Another Joe Schmoe")
    visit merge_name_path(name2.id)
    expect(page).to have_content(name2.name)
    expect(page).to have_content(name1.name)
  end
end
