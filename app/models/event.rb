class Event < ActiveRecord::Base

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

  TYPE_SOLD_UNKNOWN = "Unknown"
  TYPE_SOLD_YES = "Yes"
  TYPE_SOLD_NO = "No"
  TYPE_SOLD_GIFT = "Gift"
  TYPE_SOLD_WITHDRAWN = "Withdrawn"

  SOLD_TYPES =[
    [TYPE_SOLD_UNKNOWN, TYPE_SOLD_UNKNOWN],
    [TYPE_SOLD_YES, TYPE_SOLD_YES],
    [TYPE_SOLD_NO, TYPE_SOLD_NO],
    [TYPE_SOLD_GIFT, TYPE_SOLD_GIFT],
    [TYPE_SOLD_WITHDRAWN, TYPE_SOLD_WITHDRAWN],
  ]

  include UserFields

  belongs_to :entry

  has_many :event_agents, inverse_of: :event

  accepts_nested_attributes_for :event_agents

  scope :transactions, -> { where(primary: true) }
  scope :provenance, -> { where(primary: false) }

  validates :sold, inclusion: { in: SOLD_TYPES.map(&:first) }, if: :primary
  validates_presence_of :entry

  def get_event_agent_with_role(role)
    event_agents.select { |ea| ea.role == role }.first
  end

  # returns an EventAgent record
  def get_selling_agent
    get_event_agent_with_role(EventAgent::ROLE_SELLING_AGENT)
  end

  # returns an Agent record
  def get_selling_agent_as_agent
    ea = get_event_agent_with_role(EventAgent::ROLE_SELLING_AGENT)
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

  def display_value
    # TODO: fill out
    ea = get_seller_or_holder
    ea.agent.name if ea && ea.agent
  end

  def get_price_for_display
    [price, currency, other_currency].join " "
  end

end
