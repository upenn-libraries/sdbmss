
class Provenance < ActiveRecord::Base

  belongs_to :entry
  belongs_to :provenance_agent, class_name: 'Name', counter_cache: :provenance_count

  # Note that we do NOT validate the presence of Entry b/c
  # ActiveRecord won't find deleted entries (b/c of its default scope)
  # and complain.

  # This handy list of acquisition method types is adapted from the
  # Elysa tool developed by the Carnegie Museum of Art.
  # https://github.com/cmoa/elysa
  TYPE_ACQUISITION_METHOD_BEQUEST = "bequest"
  TYPE_ACQUISITION_METHOD_BY_DESCENT = "by_descent"
  TYPE_ACQUISITION_METHOD_BY_DESCENT_THROUGH = "by_descent_through"
  TYPE_ACQUISITION_METHOD_SALE = "sale"
  TYPE_ACQUISITION_METHOD_PURCHASE = "purchase"
  TYPE_ACQUISITION_METHOD_PURCHASE_VIA_AGENT = "purchase_via_agent"
  TYPE_ACQUISITION_METHOD_ACQUISITION = "acquisition"
  TYPE_ACQUISITION_METHOD_DEPOSIT = "deposit"
  TYPE_ACQUISITION_METHOD_AUCTION = "auction"
  TYPE_ACQUISITION_METHOD_EXCHANGE = "exchange"
  TYPE_ACQUISITION_METHOD_GIFT = "gift"
  TYPE_ACQUISITION_METHOD_GIFT_BY_EXCHANGE = "gift_by_exchange"
  TYPE_ACQUISITION_METHOD_BEQUEST_BY_EXCHANGE = "bequest_by_exchange"
  TYPE_ACQUISITION_METHOD_CONVERSION = "conversion"
  TYPE_ACQUISITION_METHOD_LOOTING = "looting"
  TYPE_ACQUISITION_METHOD_THEFT = "theft"
  TYPE_ACQUISITION_METHOD_FORCED_SALE = "forced_sale"
  TYPE_ACQUISITION_METHOD_RESTITUTION = "restitution"
  TYPE_ACQUISITION_METHOD_TRANSFER = "transfer"
  TYPE_ACQUISITION_METHOD_COMMISSION = "commission"
  TYPE_ACQUISITION_METHOD_FIELD_COLLECTION = "field_collection"
  TYPE_ACQUISITION_METHOD_WITH = "with"
  TYPE_ACQUISITION_METHOD_FOR_SALE = "for_sale"
  TYPE_ACQUISITION_METHOD_IN_SALE = "in_sale"
  TYPE_ACQUISITION_METHOD_AS_AGENT = "as_agent"

  ACQUISITION_METHOD_TYPES = [
    [TYPE_ACQUISITION_METHOD_BEQUEST, "Bequest" ],
    [TYPE_ACQUISITION_METHOD_BY_DESCENT, "By Descent" ],
    [TYPE_ACQUISITION_METHOD_BY_DESCENT_THROUGH, "By Descent Through" ],
    [TYPE_ACQUISITION_METHOD_SALE, "Sale" ],
    [TYPE_ACQUISITION_METHOD_PURCHASE, "Purchase" ],
    [TYPE_ACQUISITION_METHOD_PURCHASE_VIA_AGENT, "Purchase Via Agent" ],
    [TYPE_ACQUISITION_METHOD_ACQUISITION, "Acquisition" ],
    [TYPE_ACQUISITION_METHOD_DEPOSIT, "Deposit" ],
    [TYPE_ACQUISITION_METHOD_AUCTION, "Auction" ],
    [TYPE_ACQUISITION_METHOD_EXCHANGE, "Exchange" ],
    [TYPE_ACQUISITION_METHOD_GIFT, "Gift" ],
    [TYPE_ACQUISITION_METHOD_GIFT_BY_EXCHANGE, "Gift, By Exchange" ],
    [TYPE_ACQUISITION_METHOD_BEQUEST_BY_EXCHANGE, "Bequest, By Exchange" ],
    [TYPE_ACQUISITION_METHOD_CONVERSION, "Conversion" ],
    [TYPE_ACQUISITION_METHOD_LOOTING, "Looting" ],
    [TYPE_ACQUISITION_METHOD_THEFT, "Theft" ],
    [TYPE_ACQUISITION_METHOD_FORCED_SALE, "Forced Sale" ],
    [TYPE_ACQUISITION_METHOD_RESTITUTION, "Restitution" ],
    [TYPE_ACQUISITION_METHOD_TRANSFER, "Transfer" ],
    [TYPE_ACQUISITION_METHOD_COMMISSION, "Commission" ],
    [TYPE_ACQUISITION_METHOD_FIELD_COLLECTION, "Field Collection" ],
    [TYPE_ACQUISITION_METHOD_WITH, "With" ],
    [TYPE_ACQUISITION_METHOD_FOR_SALE, "For Sale" ],
    [TYPE_ACQUISITION_METHOD_IN_SALE, "In Sale" ],
    [TYPE_ACQUISITION_METHOD_AS_AGENT, "As Agent" ],
  ]

  # Returns a 2-item Array with start_date and end_date in the format
  # YYYY or YYYY-MM-DD, depending on how much information is in the
  # approximate date string.
  def self.parse_observed_date(date_str)
    date_str = date_str.strip

    # if entire str is a number, return it
    if (exact_date_match = /^(\d{1,4})$/.match(date_str)).present?
      year = exact_date_match[1]
      return [year, (year.to_i + 1).to_s]
    elsif (dates = SDBMSS::Util.parse_month_and_year_into_date_range(date_str)).present?
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

  def get_acquisition_method_for_display
    result = ACQUISITION_METHOD_TYPES.select { |record| record[0] == acquisition_method }.first
    result ? result[1] : nil
  end

end