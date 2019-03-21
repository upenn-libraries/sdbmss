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
    {
      model_class: "entry_scribes",
      id: id,
      fields: {
        observed_name: "'''#{observed_name}'''",
        entry_id: "<https://sdbm.library.upenn.edu/entries/#{entry_id}>",
        scribe_id: "<https://sdbm.library.upenn.edu/names/#{scribe_id}>",
        order: "'#{order}'^^xsd:integer",
        supplied_by_data_entry: "'#{supplied_by_data_entry}'^^xsd:boolean",
        uncertain_in_source: "'#{uncertain_in_source}'^^xsd:boolean"
      }
    }
=begin
    %Q(
      sdbm:entry_scribes/#{id}
      a       sdbm:entry_scribes
      sdbm:entry_scribes_id #{id}
      sdbm:entry_scribes_observed_name '#{observed_name}'
      sdbm:entry_scribes_entry_id <https://sdbm.library.upenn.edu/entries/#{entry_id}>
      sdbm:entry_scribes_scribe_id <https://sdbm.library.upenn.edu/names/#{scribe_id}>
      sdbm:entry_scribes_order #{order}
      sdbm:entry_scribes_supplied_by_data_entry '#{supplied_by_data_entry}'^^xsd:boolean
      sdbm:entry_scribes_uncertain_in_source '#{uncertain_in_source}'^^xsd:boolean
    )
=end
  end

end
