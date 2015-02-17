class EntryDate < ActiveRecord::Base
  belongs_to :entry

  validates_presence_of :entry

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

  def get_circa_verbose
    option = CIRCA_TYPES.select { |option| option[0] == circa }.first
    option[1] if option
  end

  def display_value
    sep = date.to_s.length > 0 && circa.to_s.length > 0 ? " " : ""
    get_circa_verbose.to_s + sep + date
  end

end
