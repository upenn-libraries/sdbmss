require 'rails_helper'

RSpec.describe SaleAgent, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "validations" do
    it "is valid with an agent" do
      agent = build(:sale_agent, agent: create(:name), observed_name: nil)
      expect(agent).to be_valid
    end

    it "is valid with an observed_name" do
      agent = build(:sale_agent, agent: nil, observed_name: "Some Name")
      expect(agent).to be_valid
    end

    it "is invalid without both agent and observed_name" do
      agent = build(:sale_agent, agent: nil, observed_name: nil)
      expect(agent).not_to be_valid
      expect(agent.errors[:base]).to include(/must have either Agent association or observed_name/)
    end
  end

  describe "#display_value" do
    it "returns agent name and observed name when both present" do
      name = create(:name, name: "Authorized Name")
      agent = build(:sale_agent, agent: name, observed_name: "Original Name")
      expect(agent.display_value).to eq("Authorized Name (Original Name)")
    end

    it "returns only agent name when observed_name is blank" do
      name = create(:name, name: "Authorized Name")
      agent = build(:sale_agent, agent: name, observed_name: nil)
      expect(agent.display_value).to eq("Authorized Name")
    end
  end
end
