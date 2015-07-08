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
  TYPE_SOLD_WITHDRAWN = "Withdrawn"

  SOLD_TYPES =[
    [TYPE_SOLD_UNKNOWN, TYPE_SOLD_UNKNOWN],
    [TYPE_SOLD_YES, TYPE_SOLD_YES],
    [TYPE_SOLD_NO, TYPE_SOLD_NO],
    [TYPE_SOLD_WITHDRAWN, TYPE_SOLD_WITHDRAWN],
  ]

  include UserFields

  belongs_to :entry

  before_validation :normalize

  has_many :event_agents, dependent: :destroy, inverse_of: :event

  accepts_nested_attributes_for :event_agents, allow_destroy: true

  scope :transactions, -> { where(primary: true) }
  scope :provenance, -> { where(primary: false) }

  validates :sold, inclusion: { in: SOLD_TYPES.map(&:first) }, if: :primary, allow_nil: true
  validates :currency, inclusion: { in: CURRENCY_TYPES.map(&:first) }, allow_nil: true
  validates_numericality_of :price, allow_nil: true
  validates_presence_of :entry

  has_paper_trail skip: [:created_at, :updated_at]

  # Returns a 2-item Array with start_date and end_date in the format
  # YYYY or YYYY-MM-DD, depending on how much information is in the
  # approximate date string.
  def self.parse_observed_date(date_str)
    date_str = date_str.strip

    # if entire str is a number, return it
    if (exact_date_match = /^(\d{1,4})$/.match(date_str)).present?
      year = exact_date_match[1]
      return [year, (year.to_i + 1).to_s]
    elsif (dates = SDBMSS::Util.parse_month_and_year(date_str)).present?
      return [dates[0], dates[1]]
    elsif (dates = SDBMSS::Util.parse_approximate_date_str_into_year_range(date_str)).present?
      return [dates[0], dates[1]]
    else
      parsed = Chronic.parse(date_str)
      if parsed.present?
        return [parsed.strftime("%Y-%m-%d"), (parsed + 1.day).strftime("%Y-%m-%d")]
      end
    end
    return [nil, nil]
  end

  def normalize
    # only normalize dates for Transaction records, since for
    # provenance records, the date fields are "as observed" fields.
    # TODO: this might be bad, since now start_date means 2 different
    # things; maybe we should have a separate sale_date field?
    # provenance records, the date fields are "as observed" fields
    if self.primary
      if self.start_date
        self.start_date.gsub!("-", "")
      end
      if self.end_date
        self.end_date.gsub!("-", "")
      end
      self.start_date_normalized_start = SDBMSS::Util.normalize_fuzzy_date(start_date_normalized_start)
      self.start_date_normalized_end = SDBMSS::Util.normalize_fuzzy_date(start_date_normalized_end)
      self.end_date_normalized_start = SDBMSS::Util.normalize_fuzzy_date(end_date_normalized_start)
      self.end_date_normalized_end = SDBMSS::Util.normalize_fuzzy_date(end_date_normalized_end)
    end
  end

  def get_event_agent_with_role(role)
    event_agents.select { |ea| ea.role == role }.first
  end

  # returns an EventAgent object
  def get_selling_agent
    get_event_agent_with_role(EventAgent::ROLE_SELLING_AGENT)
  end

  # returns an Name object
  def get_selling_agent_as_name
    ea = get_selling_agent
    ea.agent if ea
  end

  # returns an EventAgent object
  def get_seller_or_holder
    get_event_agent_with_role(EventAgent::ROLE_SELLER_OR_HOLDER)
  end

  # returns an Name object
  def get_seller_or_holder_as_name
    ea = get_seller_or_holder
    ea.agent if ea
  end

  # returns an EventAgent object
  def get_buyer
    get_event_agent_with_role(EventAgent::ROLE_BUYER)
  end

  # returns an Name object
  def get_buyer_as_name
    ea = get_buyer
    ea.agent if ea
  end

  def get_price_for_display
    [price, currency, other_currency].select { |o| o.present? }.join(" ")
  end

end
