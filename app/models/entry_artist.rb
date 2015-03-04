class EntryArtist < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :artist, class_name: 'Name'

  validates_presence_of :entry
  validates_presence_of :artist

  def to_s
    (artist ? artist.name : "") + certainty_flags
  end

end
