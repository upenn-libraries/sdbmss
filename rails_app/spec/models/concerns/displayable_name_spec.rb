require "rails_helper"

describe DisplayableName do

  let(:host_class) do
    Class.new do
      include DisplayableName
      attr_accessor :observed_name
    end
  end

  subject(:host) { host_class.new }

  let(:named_obj) { double("obj", name: "Some Name") }

  describe "#display_value" do
    context "when both obj and observed_name are present" do
      it "returns the name followed by observed_name in parentheses" do
        host.observed_name = "variant spelling"
        expect(host.display_value(named_obj)).to eq("Some Name (variant spelling)")
      end
    end

    context "when only obj is present" do
      it "returns the obj name" do
        host.observed_name = nil
        expect(host.display_value(named_obj)).to eq("Some Name")
      end
    end

    context "when only observed_name is present" do
      it "returns the observed_name" do
        host.observed_name = "as observed"
        expect(host.display_value(nil)).to eq("as observed")
      end
    end

    context "when neither obj nor observed_name is present" do
      it "returns an empty string" do
        host.observed_name = nil
        expect(host.display_value(nil)).to eq("")
      end
    end
  end

end
