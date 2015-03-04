class EntryArtist < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :artist, class_name: 'Name', counter_cache: :artists_count

  validates_presence_of :entry

  def to_s
    (artist ? artist.name : "") + certainty_flags
  end

end
