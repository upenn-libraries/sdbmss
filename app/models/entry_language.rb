class EntryLanguage < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  include TellBunny

  belongs_to :entry
  belongs_to :language, counter_cache: :entries_count

  validates_presence_of :entry
  validate :observed_or_authority
  validates_length_of :observed_name, :minimum => 0, :maximum => 255, :allow_blank => true

  def display_value
    [language ? language.name : nil, observed_name.present? ? "(#{observed_name})" : nil].reject(&:blank?).join(" ")
  end

  def facet_value
    language ? language.name : nil
  end

  def to_s
    display_value
  end

  def observed
    ""
  end

  def to_rdf
    {
      model_class: "entry_languages",
      id: id,
      fields: {
        observed_name: "'''#{observed_name}'''",
        entry_id: "<https://sdbm.library.upenn.edu/entries/#{entry_id}>",
        language_id: "<https://sdbm.library.upenn.edu/languages/#{language_id}>",
        order: "'#{order}'^^xsd:integer",
        supplied_by_data_entry: "'#{supplied_by_data_entry}'^^xsd:boolean",
        uncertain_in_source: "'#{uncertain_in_source}'^^xsd:boolean"
      }
    }
  end

  private

  def observed_or_authority
    if observed_name.blank? && language.blank?
      errors[:base] << "Either an observed value or authority name are required (or both)"
    end
  end

end
