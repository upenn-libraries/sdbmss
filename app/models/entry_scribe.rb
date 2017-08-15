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


  after_save do |entry_scribe|
    if entry_scribe.scribe
      entry_scribe.scribe.is_scribe = true
      entry_scribe.scribe.save!
    end
  end

  def display_value
    [scribe ? scribe.name : nil, observed_name ? "(#{observed_name})" : nil, certainty_flags].reject(&:blank?).join(" ")
  end

  def facet_value
    scribe ? scribe.name : nil
  end

  def to_s
    (scribe ? scribe.name : "") + certainty_flags
  end

  def to_fields
    {name: scribe ? scribe.name : nil, observed_name: observed_name}
  end

  def name_authority
    (scribe ? "<a href='/names/#{scribe_id}'>#{scribe}</a> " : "")
  end

end
