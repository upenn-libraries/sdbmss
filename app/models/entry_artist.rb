class EntryArtist < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :artist

  def to_s
    (artist ? artist.name : "") + certainty_flags
  end

end
