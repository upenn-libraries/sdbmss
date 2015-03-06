class EntryArtist < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName

  belongs_to :entry
  belongs_to :artist, class_name: 'Name', counter_cache: :artists_count

  validates_presence_of :entry

  validate do |entry_artist|
    if !(entry_artist.artist.present? || entry_artist.observed_name.present?)
      errors[:base] << "EntryArtist objects must have either Name association or observed_name value"
    end
  end

  def display_value
    super artist
  end

  def to_s
    (artist ? artist.name : "") + certainty_flags
  end

end
