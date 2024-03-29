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
    map = {
      model_class: "entry_languages",
      id: id,
      fields: {}
    }

    map[:fields][:observed_name]          = format_triple_object observed_name,          :string
    map[:fields][:entry_id]               = format_triple_object entry_id,               :uri,    'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:language_id]            = format_triple_object language_id,            :uri,    'https://sdbm.library.upenn.edu/languages/'
    map[:fields][:order]                  = format_triple_object order,                  :integer
    map[:fields][:supplied_by_data_entry] = format_triple_object supplied_by_data_entry, :boolean
    map[:fields][:uncertain_in_source]    = format_triple_object uncertain_in_source,    :boolean

    map
  end

  private

  def observed_or_authority
    if observed_name.blank? && language.blank?
      errors[:base] << "Either an observed value or authority name are required (or both)"
    end
  end

end
