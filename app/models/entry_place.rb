class EntryPlace < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName
  include HasPaperTrail

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

end