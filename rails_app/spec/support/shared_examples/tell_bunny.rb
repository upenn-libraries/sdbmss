RSpec.shared_examples "a TellBunny-enabled model" do
  let(:model_instance) { create(described_class.name.underscore.to_sym) }

  describe "#format_triple_object" do
    it "formats integers correctly" do
      expect(model_instance.format_triple_object(123, :integer)).to eq("'123'^^xsd:integer")
    end

    it "formats strings with triple quotes" do
      expect(model_instance.format_triple_object("test", :string)).to eq("'''test'''")
    end

    it "formats URIs correctly" do
      url_base = 'https://sdbm.library.upenn.edu/names/'
      expect(model_instance.format_triple_object(1, :uri, url_base)).to eq("<https://sdbm.library.upenn.edu/names/1>")
    end

    it "raises error for URI without url_base" do
      expect { model_instance.format_triple_object(1, :uri) }.to raise_error(/No `url_base` supplied/)
    end
  end

  describe "#rdf_string_prep" do
    it "strips leading and trailing single quotes" do
      expect(model_instance.rdf_string_prep("'quoted'")).to eq("\\'quoted\\'")
    end

    it "removes carriage returns and line feeds" do
      expect(model_instance.rdf_string_prep("line1\r\nline2")).to eq("line1line2")
    end
  end

  describe "#to_rdf" do
    it "returns a hash or string representation" do
      rdf = model_instance.to_rdf
      expect(rdf).to be_a(Hash).or be_a(String)
    end
  end
end
