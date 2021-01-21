class EntryScribe < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName
  include HasPaperTrail

  include TellBunny

  belongs_to :entry
  belongs_to :scribe, class_name: 'Name', counter_cache: :scribes_count

  validates_length_of :observed_name, :minimum => 0, :maximum => 255, :allow_blank => true
  validates_presence_of :entry

  validate do |entry_scribe|
    if !(entry_scribe.scribe.present? || entry_scribe.observed_name.present?)
      errors[:base] << "EntryScribe objects must have either Name association or observed_name value"
    end
  end


  after_save do |entry_scribe|
    if entry_scribe.scribe && !entry_scribe.scribe.is_scribe
      entry_scribe.scribe.is_scribe = true
      entry_scribe.scribe.save!
    end
  end

  def display_value
    [scribe ? scribe.name : nil, observed_name.present? ? "(#{observed_name})" : nil].reject(&:blank?).join(" ").html_safe
  end

  def facet_value
    scribe ? scribe.name : nil
  end

  def to_s
    (scribe ? scribe.name : "") + certainty_flags
  end

  def to_rdf
    map = {
      model_class: "entry_scribes",
      id: id,
      fields: {}
    }

    map[:fields][:observed_name]          = format_triple_object observed_name,          :string
    map[:fields][:entry_id]               = format_triple_object entry_id,               :uri,            'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:scribe_id]              = format_triple_object scribe_id,              :uri,            'https://sdbm.library.upenn.edu/names/'
    map[:fields][:order]                  = format_triple_object order,                  :integer
    map[:fields][:supplied_by_data_entry] = format_triple_object supplied_by_data_entry, :boolean
    map[:fields][:uncertain_in_source]    = format_triple_object uncertain_in_source,    :boolean

    map
  end

end
