class EntryPlace < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName
  include HasPaperTrail

  belongs_to :entry
  belongs_to :place, counter_cache: :entries_count

  validates_presence_of :entry

  def display_value
    [place ? place.name : nil, observed_name ? "(#{observed_name})" : nil, certainty_flags ].reject(&:blank?).join(" ")
  end

  def to_s
    (place && place.name ? place.name : "") + certainty_flags
  end

  def to_fields
    {observed_name: observed_name, name: place ? place.name : nil}
  end

  def name_authority
    (place ? "<a href='/places/#{place_id}'>#{place}</a> " : "")
  end

end
