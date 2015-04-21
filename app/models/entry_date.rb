require 'chronic'

class EntryDate < ActiveRecord::Base
  belongs_to :entry

  validates_presence_of :entry

  validate do |entry_date|
    # both must be present if either is present
    if entry_date.date_normalized_start.present? && !entry_date.date_normalized_end.present?
      errors[:date_normalized_end] = "date_normalized_end is required if date_normalized_start is present"
    end
    if !entry_date.date_normalized_start.present? && entry_date.date_normalized_end.present?
      errors[:date_normalized_start] = "date_normalized_start is required if date_normalized_end is present"
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
      return [year, year]
    elsif SDBMSS::Util.resembles_approximate_date_str(date_str)
      date = SDBMSS::Util.normalize_approximate_date_str_to_year_range(date_str)
      return [date[0], date[1]]
    else
      parsed = Chronic.parse(date_str)
      if parsed.present?
        return [parsed.strftime("%Y-%m-%d"), parsed.strftime("%Y-%m-%d")]
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
    sep = date.to_s.length > 0 && circa.to_s.length > 0 ? " " : ""
    circa_verbose.to_s + sep + date
  end

end
