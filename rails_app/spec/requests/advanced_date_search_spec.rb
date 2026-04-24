require "rails_helper"
require "nokogiri"

RSpec.describe "Advanced manuscript date search", type: :request, solr: true do
  let(:admin_user) { create(:admin) }

  def create_date_entry(source:, observed_date:, start_date:, end_date:)
    Entry.create!(
      source: source,
      catalog_or_lot_number: "1",
      transaction_type: Entry::TYPE_TRANSACTION_SALE,
      entry_dates_attributes: [
        {
          observed_date: observed_date,
          date_normalized_start: start_date,
          date_normalized_end: end_date
        }
      ],
      created_by: admin_user,
      approved: true
    )
  end

  def search_public_ids(start_date:, end_date:)
    start_value = start_date.presence || "*"
    end_value = end_date.presence || "*"

    get search_catalog_path, params: {
      search_field: "advanced",
      manuscript_date: ["[#{start_value} TO #{end_value}]"]
    }

    expect(response).to have_http_status(:success)

    doc = Nokogiri::HTML(response.body)
    doc.css("#documents a").map(&:text).grep(/\ASDBM_\d+\z/).uniq
  end

  before do
    source = create(
      :edit_test_source,
      created_by: admin_user,
      date: "20150101",
      title: "Request Date Search Source"
    )

    @range_entry = create_date_entry(
      source: source,
      observed_date: "1900 to 1950",
      start_date: "1900",
      end_date: "1951"
    )
    @exact_entry = create_date_entry(
      source: source,
      observed_date: "1502",
      start_date: "1502",
      end_date: "1503"
    )

    SampleIndexer.index_records!(@range_entry, @exact_entry)
  end

  it "matches the 1900-1950 range matrix" do
    expect(search_public_ids(start_date: "1899", end_date: "1899")).to eq([])
    expect(search_public_ids(start_date: "1951", end_date: "1951")).to eq([])

    expect(search_public_ids(start_date: "1900", end_date: "1900")).to eq([@range_entry.public_id])
    expect(search_public_ids(start_date: "1921", end_date: "1921")).to eq([@range_entry.public_id])
    expect(search_public_ids(start_date: "1950", end_date: "1950")).to eq([@range_entry.public_id])

    expect(search_public_ids(start_date: "1875", end_date: "1900")).to eq([@range_entry.public_id])
    expect(search_public_ids(start_date: "1910", end_date: "1915")).to eq([@range_entry.public_id])
    expect(search_public_ids(start_date: "1950", end_date: "1960")).to eq([@range_entry.public_id])

    expect(search_public_ids(start_date: "1800", end_date: "1899")).to eq([])
    expect(search_public_ids(start_date: "1951", end_date: "1960")).to eq([])

    expect(search_public_ids(start_date: "1890", end_date: nil)).to eq([@range_entry.public_id])
    expect(search_public_ids(start_date: "1900", end_date: nil)).to eq([@range_entry.public_id])
    expect(search_public_ids(start_date: "1950", end_date: nil)).to eq([@range_entry.public_id])
    expect(search_public_ids(start_date: "1951", end_date: nil)).to eq([])

    expect(search_public_ids(start_date: nil, end_date: "1899")).to eq([@exact_entry.public_id])
    expect(search_public_ids(start_date: nil, end_date: "1900")).to match_array([@range_entry.public_id, @exact_entry.public_id])
    expect(search_public_ids(start_date: nil, end_date: "1950")).to match_array([@range_entry.public_id, @exact_entry.public_id])
    expect(search_public_ids(start_date: nil, end_date: "1960")).to match_array([@range_entry.public_id, @exact_entry.public_id])
  end

  it "matches the exact-date 1502 matrix" do
    expect(search_public_ids(start_date: "1501", end_date: "1501")).to eq([])
    expect(search_public_ids(start_date: "1502", end_date: "1502")).to eq([@exact_entry.public_id])
    expect(search_public_ids(start_date: "1503", end_date: "1503")).to eq([])

    expect(search_public_ids(start_date: "1475", end_date: "1502")).to eq([@exact_entry.public_id])
    expect(search_public_ids(start_date: "1475", end_date: "1550")).to eq([@exact_entry.public_id])
    expect(search_public_ids(start_date: "1502", end_date: "1510")).to eq([@exact_entry.public_id])

    expect(search_public_ids(start_date: "1400", end_date: "1501")).to eq([])
    expect(search_public_ids(start_date: "1503", end_date: "1510")).to eq([])
  end
end
