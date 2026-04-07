
require 'viaf'

describe "VIAF" do
  def stub_viaf_response(body)
    response = double('viaf response', code: '200', body: body)
    allow(VIAF).to receive(:make_viaf_request).and_return(response)
    response
  end

  it "gets data" do
    stub_viaf_response('{"id":"102333412","name":"Boethius"}')
    json = VIAF.get_data("102333412").body
    expect(json.length).to be > 0
    expect(JSON.parse(json)).to be_a(Hash)
  end

  it "does an sru search" do
    stub_viaf_response('<?xml version="1.0" encoding="UTF-8"?><searchRetrieveResponse/>')
    xml = VIAF.sru_search("local.personalNames all \"Boethius\"").body
    expect(xml.length).to be > 0
    xml_doc = Nokogiri::XML(xml)
  end

  it "does autosuggest" do
    stub_viaf_response('{"result":"Boethius"}')
    json = VIAF.autosuggest("Boethius").body
    expect(json.length).to be > 0
    expect(JSON.parse(json)).to be_a(Hash)
  end

end
