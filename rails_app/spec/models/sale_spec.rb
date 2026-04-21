require 'rails_helper'

RSpec.describe Sale, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "validations" do
    it "is valid with an entry" do
      sale = build(:sale)
      expect(sale).to be_valid
    end

    it "is invalid without an entry" do
      sale = build(:sale, entry: nil)
      expect(sale).not_to be_valid
    end

    it "validates inclusion of sold status" do
      sale = build(:sale, sold: "InvalidStatus")
      expect(sale).not_to be_valid
    end

    it "validates numericality of price" do
      sale = build(:sale, price: "abc")
      expect(sale).not_to be_valid
    end
  end

  describe "#get_complete_price_for_display" do
    it "returns price and currency" do
      sale = build(:sale, price: 123.45, currency: "USD")
      expect(sale.get_complete_price_for_display).to eq("123.45 USD")
    end

    it "includes other_currency if present" do
      sale = build(:sale, price: 100, currency: "USD", other_currency: "Gold")
      expect(sale.get_complete_price_for_display).to eq("100.00 USD Gold")
    end
  end

  describe "agent accessors" do
    let(:sale) { create(:sale) }
    let(:agent_name) { create(:name, name: "Unique Selling Agent #{SecureRandom.hex(4)}") }
    let!(:selling_agent) { create(:sale_agent, sale: sale, agent: agent_name, role: SaleAgent::ROLE_SELLING_AGENT) }
    let!(:buyer_agent) { create(:sale_agent, sale: sale, role: SaleAgent::ROLE_BUYER, observed_name: "Buyer X", agent: nil) }

    it "returns selling agents" do
      expect(sale.get_selling_agents).to include(selling_agent)
      expect(sale.get_selling_agents).not_to include(buyer_agent)
    end

    it "returns formatted selling agent names" do
      expect(sale.get_selling_agents_names).to include(agent_name.name)
      expect(sale.get_selling_agents_names).to include("Observed Name")
    end

    it "returns formatted buyer names" do
      expect(sale.get_buyers_names).to eq(" (Buyer X)")
    end
  end
end
