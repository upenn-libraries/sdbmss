
class SaleAgent < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :sale
  belongs_to :agent, class_name: 'Name', counter_cache: :sale_agents_count

  validates_presence_of :sale

  validate do |sale_agent|
    if !(sale_agent.agent.present? || sale_agent.observed_name.present?)
      errors[:base] << "SaleAgent objects must have either Agent association or observed_name value"
    end
  end

  ROLE_SELLER_OR_HOLDER = "seller_or_holder"
  ROLE_SELLING_AGENT = "selling_agent"
  ROLE_BUYER = "buyer"

  ROLE_TYPES = [
    [ROLE_SELLER_OR_HOLDER, "Seller or Holder"],
    [ROLE_SELLING_AGENT, "Selling Agent"],
    [ROLE_BUYER, "Buyer"],
  ]

  def entry
    sale.entry
  end

  def name_authority
    (agent ? "<a href='/names/#{agent_id}'>#{agent}</a> " : "")
  end

  def observed
    ""
  end

  def display_value
    
  end

end
