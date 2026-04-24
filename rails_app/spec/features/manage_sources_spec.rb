require "rails_helper"

describe "Manage sources", :js => true do
  include DataEntryHelpers

  let(:password) { "somethingreallylong" }
  let(:admin_user) { create(:admin) }
  let(:source_title) { "my test source" }
  let(:source) do
    Source.find_or_create_by(title: source_title) do |record|
      record.source_type = SourceType.auction_catalog
      record.created_by = admin_user
    end
  end

  def search_block(index)
    all(".search-block", visible: :all)[index]
  end

  def configure_search_row(index, value:, field:)
    within(search_block(index)) do
      fill_in "search_value", with: value
      select field, from: "search_field"
    end
  end

  before :each do
    source
    Source.index
    Sunspot.commit
    fast_login(admin_user)
  end

  it "should perform a search with multiple values for the same field (AND)" do
    visit sources_path

    find('#addSearch').click()

    configure_search_row(0, value: "Morgan", field: "Title")
    configure_search_row(1, value: "Libreria", field: "Title")

    find('#search_submit').click()
  end

  it "should perform a search with multiple values for the same field (ANY)" do
    visit sources_path

    find('#addSearch').click()

    configure_search_row(0, value: "Morgan", field: "Title")
    configure_search_row(1, value: "test", field: "Title")

    select "Any", from: "search_op"

    find('#search_submit').click()
    expect(page).not_to have_selector("#spinner", visible: true)

    expect(page).to have_content source.title
  end

  it "should delete a Source" do
    # this is a very rough test!
    count = Source.count

    visit sources_path
    accept_data_confirm_modal_from do
      find(".delete-link", match: :first).trigger('click')
    end

    expect(page).to have_no_content(source.title)
    expect(Source.count).to eq(count-1)
  end

  it "should create a new Source" do
    new_source_title = "Completely unique source"

    visit new_source_path(source_type: SourceType.auction_catalog.id)

    find('#title').set new_source_title
    fill_in 'source_date', with: '2014-02-03'
    click_button "Save"

    sleep 1
    created_source = Source.find_by!(title: new_source_title)
    expect(created_source).to have_attributes(title: new_source_title)
  end

  it "should edit an existing Source" do
    visit edit_source_path(source)

    updated_title = "Utterly specific title"

    find('#title').set updated_title
    click_button "Save"

    sleep 1
    updated_source = Source.find_by!(title: updated_title)
    expect(updated_source).to have_attributes(title: updated_title)
  end

end
