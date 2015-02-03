
# A concern that supplies #certainty_flags
module CertaintyFlags

  extend ActiveSupport::Concern

  # returns a str with ? and * indicators, for appending to strings
  def certainty_flags
    (uncertain_in_source ? "?" : "") + (supplied_by_data_entry ? "*" : "")
  end

end
