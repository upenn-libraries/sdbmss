require "rails_helper"

describe SanitizeHelper::CommentScrubber do
  let(:scrubber) { described_class.new }

  def stub_node(name)
    double("Nokogiri::XML::Node", name: name)
  end

  describe "#allowed_node?" do
    it "allows textarea nodes" do
      expect(scrubber.allowed_node?(stub_node("textarea"))).to be true
    end

    it "allows nodes whose name contains 'http' (text nodes with URLs)" do
      expect(scrubber.allowed_node?(stub_node("http"))).to be true
    end

    it "rejects regular element nodes" do
      expect(scrubber.allowed_node?(stub_node("script"))).to be false
    end
  end

  describe "#skip_node?" do
    it "skips nodes whose name includes 'http'" do
      expect(scrubber.skip_node?(stub_node("http://example.com"))).to be true
    end

    it "does not skip regular nodes" do
      expect(scrubber.skip_node?(stub_node("p"))).to be false
    end
  end
end
