require 'rails_helper'

RSpec.describe SolrDocument do
  let(:resultset) { instance_double("SDBMSS::Blacklight::ResultSet", add: nil) }
  let(:response) { double("response", objects_resultset: resultset) }

  before do
    allow(resultset).to receive(:add)
    allow(response).to receive(:objects_resultset=)
  end

  describe "#to_param" do
    it "returns the entry_id if present" do
      doc = SolrDocument.new({ entry_id: 123 }, response)
      expect(doc.to_param).to eq("123")
    end

    it "strips 'Entry ' from the id if entry_id is missing" do
      doc = SolrDocument.new({ id: "Entry 456" }, response)
      expect(doc.to_param).to eq("456")
    end
  end

  describe "#model_object" do
    it "fetches the entry from the resultset" do
      entry = instance_double("Entry", id: 789)
      allow(resultset).to receive(:get).with(789).and_return(entry)
      
      doc = SolrDocument.new({ entry_id: 789 }, response)
      expect(doc.model_object).to eq(entry)
    end
  end
end
