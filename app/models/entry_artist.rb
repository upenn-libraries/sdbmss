class EntryArtist < ActiveRecord::Base
  belongs_to :entry
  belongs_to :artist
end
