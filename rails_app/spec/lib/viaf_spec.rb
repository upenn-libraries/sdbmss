
require 'viaf'

describe "VIAF" do

  it "gets data" do
    json = VIAF.get_data("102333412").body
    expect(json.length).to be > 0
    expect(JSON.parse(json)).to be_a(Hash)
  end

  it "does an sru search" do
    xml = VIAF.sru_search("local.personalNames all \"Boethius\"").body
    expect(xml.length).to be > 0
    xml_doc = Nokogiri::XML(xml)
  end

  it "does autosuggest" do
    json = VIAF.autosuggest("Boethius").body
    expect(json.length).to be > 0
    expect(JSON.parse(json)).to be_a(Hash)
  end

end
