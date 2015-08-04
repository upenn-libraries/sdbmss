class EntryScribe < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName
  include HasPaperTrail

  belongs_to :entry
  belongs_to :scribe, class_name: 'Name', counter_cache: :scribes_count

  validates_presence_of :entry

  validate do |entry_scribe|
    if !(entry_scribe.scribe.present? || entry_scribe.observed_name.present?)
      errors[:base] << "EntryScribe objects must have either Name association or observed_name value"
    end
  end

  def display_value
    super scribe
  end

  def to_s
    (scribe ? scribe.name : "") + certainty_flags
  end

end
