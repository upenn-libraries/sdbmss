
# A concern that supplies #certainty_flags
module CertaintyFlags

  extend ActiveSupport::Concern

  # returns a str with ? and * indicators, for appending to strings
  def certainty_flags
    ((uncertain_in_source ? "<span class='fa fa-question-circle' title='Uncertain in Source'></span>" : "") + (supplied_by_data_entry ? "<span class='fa fa-asterisk' title='Inferred from Source'></span>" : "")).html_safe
  end

end
