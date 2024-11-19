class EntryPlace < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName
  include HasPaperTrail

  include TellBunny

  belongs_to :entry
  belongs_to :place, counter_cache: :entries_count

  validates_presence_of :entry
  validates_length_of :observed_name, :minimum => 0, :maximum => 255, :allow_blank => true

  def display_value
    [place ? place.to_s : nil, observed_name.present? ? "(#{observed_name})" : nil ].reject(&:blank?).join(" ").html_safe
  end

  def facet_value
    place ? place.name : nil
  end

  def to_s
    (place && place.name ? place.name : "") + certainty_flags
  end

  def to_rdf
    map = {
      model_class: "entry_places",
      id: id,
      fields: {}
    }

    map[:fields][:observed_name]          = format_triple_object observed_name,          :string
    map[:fields][:place_id]               = format_triple_object place_id,               :uri,    'https://sdbm.library.upenn.edu/places/'
    map[:fields][:entry_id]               = format_triple_object entry_id,               :uri,    'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:order]                  = format_triple_object order,                  :integer
    map[:fields][:supplied_by_data_entry] = format_triple_object supplied_by_data_entry, :boolean
    map[:fields][:uncertain_in_source]    = format_triple_object uncertain_in_source,    :boolean

    map
  end

end