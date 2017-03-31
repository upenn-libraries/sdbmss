
require 'json'
require "rails_helper"
require 'net/http'

# exercise the #entries_to_index_on_update methods on relevant model
# class objects
describe "entries_to_index_on_update" do

  before :all do
#    SDBMSS::ReferenceData.create_all

    SDBMSS::Util.wait_for_solr_to_be_current
  end

  it "should work on all models" do
    place = Place.find_by(name: 'Italy, Tuscany, Florence')
    expect(place.entries_to_index_on_update.count).to eq(1)

    language = Language.find_by(name: 'French')
    expect(language.entries_to_index_on_update.count).to eq(1)

    name = Name.find_by(name: "Sotheby's")
    expect(name.entries_to_index_on_update.count).to eq(4)

    source = Source.find_by(title: "Catalogue 213: Fine and Important Manuscripts and Printed Books")
    expect(source.entries_to_index_on_update.count).to eq(6)
  end

end
