class EntryScribe < ActiveRecord::Base
  belongs_to :entry
  belongs_to :scribe
end
