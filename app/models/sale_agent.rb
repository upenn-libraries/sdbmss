
class SaleAgent < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  include TellBunny

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

  def display_value
    [agent ? agent.name : nil, observed_name.present? ? "(#{observed_name})" : nil].reject(&:blank?).join(" ")
  end

  def facet_value
    agent ? agent.name : nil
  end

  def observed
    ""
  end

  def to_rdf
    map = {
      model_class: "sale_agents",
      id: id,
      fields: {}
    }

    map[:fields][:sale_id]                = format_triple_object sale_id,                :uri,    'https://sdbm.library.upenn.edu/sales/'
    map[:fields][:observed_name]          = format_triple_object observed_name,          :string
    map[:fields][:agent_id]               = format_triple_object agent_id,               :uri,    'https://sdbm.library.upenn.edu/names/'
    map[:fields][:role]                   = format_triple_object role,                   :string
    map[:fields][:supplied_by_data_entry] = format_triple_object supplied_by_data_entry, :boolean
    map[:fields][:uncertain_in_source]    = format_triple_object uncertain_in_source,    :boolean

    map
  end

end
