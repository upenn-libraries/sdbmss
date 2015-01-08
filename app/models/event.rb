class Event < ActiveRecord::Base
  belongs_to :entry

  has_many :event_agents

  scope :transactions, -> { where(primary: true) }
  scope :provenance, -> { where(primary: false) }

  CURRENCY_TYPES = [
    ["EUR", "EUR"],
    ["GBP", "GBP"],
    ["USD", "USD"],
    ["CHF", "CHF"],
    ["FRF", "FRF"],
    ["BEF", "BEF"],
    ["DEM", "DEM"],
    ["ITL", "ITL"],
    ["DKK", "DKK"],
    ["JPY", "JPY"],
  ]

  SOLD_TYPES =[
    ["YES", "YES"],
    ["NO", "NO"],
    ["GIFT", "GIFT"],
  ]

  def get_event_agent_with_role(role)
    event_agents.select { |ea| ea.role == role }.first
  end

  # returns an EventAgent record
  def get_seller_agent
    get_event_agent_with_role(EventAgent::ROLE_SELLER_AGENT)
  end

  # returns an Agent record
  def get_seller_agent_as_agent
    ea = get_event_agent_with_role(EventAgent::ROLE_SELLER_AGENT)
    ea.agent if ea
  end

  # returns an EventAgent record
  def get_seller_or_holder
    get_event_agent_with_role(EventAgent::ROLE_SELLER_OR_HOLDER)
  end

  # returns an Agent record
  def get_seller_or_holder_as_agent
    ea = get_event_agent_with_role(EventAgent::ROLE_SELLER_OR_HOLDER)
    ea.agent if ea
  end

  # returns an EventAgent record
  def get_buyer
    get_event_agent_with_role(EventAgent::ROLE_BUYER)
  end

  # returns an Agent record
  def get_buyer_as_agent
    ea = get_event_agent_with_role(EventAgent::ROLE_BUYER)
    ea.agent if ea
  end

  def get_display_value
    # TODO: fill out
    ea = get_seller_or_holder
    ea.agent.name if ea && ea.agent
  end

  def get_price_for_display
    [price, currency, other_currency].join " "
  end

end
