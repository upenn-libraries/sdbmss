require "rails_helper"

describe ApplicationHelper, type: :helper do
  describe "#get_date_display" do
    let(:today) { Time.now.to_date }

    it "returns 'today' for today's date" do
      expect(helper.get_date_display(today, today)).to eq("today")
    end

    it "returns 'yesterday' for 2 days ago" do
      expect(helper.get_date_display(today - 2, today)).to eq("yesterday")
    end

    it "returns weeks ago for dates within 62 days" do
      expect(helper.get_date_display(today - 14, today)).to eq("2 week(s) ago")
    end

    it "returns months ago for dates within a year" do
      expect(helper.get_date_display(today - 93, today)).to eq("3 month(s) ago")
    end

    it "returns years ago for dates older than a year" do
      expect(helper.get_date_display(today - 730, today)).to eq("2 year(s) ago")
    end
  end

  describe "#format_fuzzy_date" do
    it "delegates to SDBMSS::Util.format_fuzzy_date" do
      allow(SDBMSS::Util).to receive(:format_fuzzy_date).with("19991231").and_return("1999-12-31")
      expect(helper.format_fuzzy_date("19991231")).to eq("1999-12-31")
    end
  end
end
