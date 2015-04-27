require 'chronic'

# Important note about dates:

# The date range represented by the date_normalized_start and
# date_normalized_end fields are end-exclusive: ie. a value falls
# within the range if start <= value < end. We do this to avoid
# problems with boundaries down the line.
#
# One such discussion can be found here:
# http://qedcode.com/content/exclusive-end-dates
#
class EntryDate < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry

  validates_presence_of :entry

  validates :date_normalized_start, numericality: { only_integer: true }, allow_blank: true
  validates :date_normalized_end, numericality: { only_integer: true }, allow_blank: true

  validate do |entry_date|
    if entry_date.date_normalized_start.present? && !entry_date.date_normalized_end.present? &&
       entry_date.date_normalized_start.to_i >= entry_date.date_normalized_end.to_i
      errors[:date_normalized_start] = "date_normalized_start must be earlier than date_normalized_end"
    end
  end

  has_paper_trail skip: [:created_at, :updated_at]

  CIRCA_TYPES = [
    ["C", "Circa"],
    ["C?", "Circa (Very Uncertain)"],
    ["CCENT", "Circa Century"],
    ["C1H", "Circa 1st Half of Century"],
    ["C2H", "Circa 2nd Half of Century"],
    ["C1Q", "Circa 1st Quarter or Century"],
    ["C2Q", "Circa 2nd Quarter of Century"],
    ["C3Q", "Circa 3rd Quarter of Century"],
    ["C4Q", "Circa 4th Quarter of Century"],
    ["CEARLY", "Circa Early Part of Century"],
    ["CMID", "Circa Mid Century"],
    ["CLATE", "Circa Late Part of Century"],
  ]

  # returns a 2-item Array with start_date and end_date
  def self.normalize_date(date_str)

    date_str = date_str.strip

    # if entire str is a number, return it
    if (exact_date_match = /^(\d{1,4})$/.match(date_str)).present?
      year = exact_date_match[1]
      return [year, (year.to_i + 1).to_s]
    elsif SDBMSS::Util.resembles_approximate_date_str(date_str)
      date = SDBMSS::Util.normalize_approximate_date_str_to_year_range(date_str)
      return [date[0], date[1]]
    else
      parsed = Chronic.parse(date_str)
      if parsed.present?
        return [parsed.strftime("%Y-%m-%d"), (parsed + 1.day).strftime("%Y-%m-%d")]
      end
    end
    return [nil, nil]
  end

  def circa_verbose
    option = CIRCA_TYPES.select { |option| option[0] == circa }.first
    option[1] if option
  end

  # examines observed_date and based on it, populates
  # date_normalized_start and date_normalized_end fields with
  # reasonable values. This is a handy thing to call from data
  # import/migration scripts after setting observed_date.
  def normalize_observed_date
    if observed_date.present?
      start_date, end_date = self.class.normalize_date(observed_date)
      self.date_normalized_start = start_date
      self.date_normalized_end = end_date
    end
  end

  def display_value
    val = observed_date || ""
    if date_normalized_start != observed_date
      if date_normalized_end.blank?
        val += " (after #{date_normalized_start})"
      elsif date_normalized_start.blank?
        val += " (before #{date_normalized_end})"
      else
        val += " (#{date_normalized_start} to #{date_normalized_end})"
      end
    end
    val + certainty_flags
  end

end
