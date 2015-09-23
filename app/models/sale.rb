
# This really represents a 'Transaction' but we call it 'Sale' because
# transaction is a reserved name for associations in ActiveRecord and
# causes problems.
#
# It's a quirk that there is a 1-Many relation between Entry and Sale;
# this is an artifact of how Sale used to be something else. Ideally,
# Entry should have a FK to a Sale record. But it probably doesn't
# really matter.

class Sale < ActiveRecord::Base

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
  TYPE_SOLD_WITHDRAWN = "Withdrawn"

  SOLD_TYPES =[
    [TYPE_SOLD_UNKNOWN, TYPE_SOLD_UNKNOWN],
    [TYPE_SOLD_YES, TYPE_SOLD_YES],
    [TYPE_SOLD_NO, TYPE_SOLD_NO],
    [TYPE_SOLD_WITHDRAWN, TYPE_SOLD_WITHDRAWN],
  ]

  include UserFields
  include HasPaperTrail

  belongs_to :entry

  before_validation :normalize

  has_many :sale_agents, dependent: :destroy, inverse_of: :sale

  accepts_nested_attributes_for :sale_agents, allow_destroy: true

  validates :sold, inclusion: { in: SOLD_TYPES.map(&:first) }, allow_nil: true
  validates :currency, inclusion: { in: CURRENCY_TYPES.map(&:first) }, allow_nil: true
  validates_numericality_of :price, allow_nil: true
  validates_presence_of :entry

  def normalize
    if date
      date.gsub!("-", "")
    end
  end

  def get_sale_agent_with_role(role)
    sale_agents.select { |ea| ea.role == role }.first
  end

  # returns an SaleAgent object
  def get_selling_agent
    get_sale_agent_with_role(SaleAgent::ROLE_SELLING_AGENT)
  end

  # returns an Name object
  def get_selling_agent_as_name
    ea = get_selling_agent
    ea.agent if ea
  end

  # returns an SaleAgent object
  def get_seller_or_holder
    get_sale_agent_with_role(SaleAgent::ROLE_SELLER_OR_HOLDER)
  end

  # returns an Name object
  def get_seller_or_holder_as_name
    ea = get_seller_or_holder
    ea.agent if ea
  end

  # returns an SaleAgent object
  def get_buyer
    get_sale_agent_with_role(SaleAgent::ROLE_BUYER)
  end

  # returns an Name object
  def get_buyer_as_name
    ea = get_buyer
    ea.agent if ea
  end

  def get_price_normalized
    price.present? ? ('%.2f' % price) : price
  end

  def get_complete_price_for_display
    [get_price_normalized, currency, other_currency].select { |o| o.present? }.join(" ")
  end

end
