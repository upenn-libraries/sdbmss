require 'chronic'

# Important notes about dates:
#
# In this model, The date range fields for searching are in years only
# (YYYY).
#
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
  include HasPaperTrail

  belongs_to :entry

  validates_presence_of :entry

  validates :date_normalized_start, numericality: { only_integer: true }, allow_blank: true
  validates :date_normalized_end, numericality: { only_integer: true }, allow_blank: true

  validate do |entry_date|
    if entry_date.date_normalized_start.present? && entry_date.date_normalized_end.present? &&
       entry_date.date_normalized_start.to_i >= entry_date.date_normalized_end.to_i
      errors[:date_normalized_start] = "date_normalized_start must be earlier than date_normalized_end"
    end
  end

  # returns a 2-item Array with start_date and end_date in the format
  # YYYY.
  def self.parse_observed_date(date_str)
    date_str = date_str.strip

    # if entire str is a number, return it
    if (exact_date_match = /^(\d{1,4})$/.match(date_str)).present?
      year = exact_date_match[1].to_i
      return [year, (year + 1)]
    # otherwise attempt to parse it based on certain conventions (circa, century, etc.)
    elsif (dates = SDBMSS::Util.parse_approximate_date_str_into_year_range(date_str)).present? && (dates[0].present? && dates[1].present?)
      return [dates[0], dates[1]]
    else
      begin
        return self.parse_default_date(date_str)
      # catch argument error sent to Chronic, for some reason was triggered by "Tenth", and similar strings
      rescue ArgumentError
        puts "WARNING: No time information in '#{date_str}', and convention is not recognized by CHRONIC date parser."
      end
    end
    return [nil, nil]
  end

  def self.parse_default_date(date_str)
    parsed = Chronic.parse(date_str)
    if parsed.present?
      return [parsed.strftime("%Y").to_i, (parsed + 1.year).strftime("%Y").to_i]
    else
      return [nil, nil]
    end
  end

  # examines observed_date and based on it, populates
  # date_normalized_start and date_normalized_end fields with
  # reasonable values. This is a handy thing to call from data
  # import/migration scripts after setting observed_date.
  def normalize_observed_date
    if observed_date.present?
      start_date, end_date = self.class.parse_observed_date(observed_date)
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

  def to_s
    display_value
  end

  def to_fields
    {observed_date: observed_date, start_date: date_normalized_start, end_date: date_normalized_end}
  end

  # returns a str of the normalized date range
  def normalized_date_range_str
    if date_normalized_start.to_i + 1 == date_normalized_end.to_i
      return "#{date_normalized_start}"
    elsif date_normalized_start.present? || date_normalized_end.present?
      return "#{date_normalized_start} - #{date_normalized_end}"
    end
    return ""
  end

end
