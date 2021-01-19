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

    map[:fields][:observed_name]          = "'''#{rdf_string_prep observed_name}'''"               if observed_name.present?
    map[:fields][:place_id]               = "<https://sdbm.library.upenn.edu/places/#{place_id}>"  if place_id.present?
    map[:fields][:entry_id]               = "<https://sdbm.library.upenn.edu/entries/#{entry_id}>" if entry_id.present?
    map[:fields][:order]                  = "'#{order}'^^xsd:integer"                              if order.present?
    map[:fields][:supplied_by_data_entry] = "'#{supplied_by_data_entry}'^^xsd:boolean"             unless supplied_by_data_entry.nil?
    map[:fields][:uncertain_in_source]    = "'#{uncertain_in_source}'^^xsd:boolean"                unless uncertain_in_source.nil?

    map
  end

end