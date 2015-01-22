
require "rails_helper"

describe "Public search" do

  it "should load successfully" do
    visit root_path
    expect(page).to have_selector("input#q")
  end

  it "should display all entries" do
    visit root_path
    click_button('search')
    expect(page).to have_selector("#documents")
  end

  it "should 404 on request for deleted entry"

end
