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
    {
      model_class: "entry_places",
      id: id,
      fields: {
        observed_name: "'''#{observed_name}'''",
        place_id: "<https://sdbm.library.upenn.edu/places/#{place_id}>",
        entry_id: "<https://sdbm.library.upenn.edu/entries/#{entry_id}>",
        order: "'#{order}'^^xsd:integer",
        supplied_by_data_entry: "'#{supplied_by_data_entry}'^^xsd:boolean",
        uncertain_in_source: "'#{uncertain_in_source}'^^xsd:boolean"
      }
    }
=begin
    %Q(
      sdbm:entry_places/#{id}
      a       sdbm:entry_places
      sdbm:entry_places_id #{id}
      sdbm:entry_places_observed_name '#{observed_name}'
      sdbm:entry_places_place_id <https://sdbm.library.upenn.edu/places/#{place_id}>
      sdbm:entry_places_entry_id <https://sdbm.library.upenn.edu/entries/#{entry_id}>
      sdbm:entry_places_order #{order}
      sdbm:entry_places_supplied_by_data_entry '#{supplied_by_data_entry}'^^xsd:boolean
      sdbm:entry_places_uncertain_in_source '#{uncertain_in_source}'^^xsd:boolean
    )
=end
  end

end