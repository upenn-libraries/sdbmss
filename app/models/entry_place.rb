class EntryPlace < ActiveRecord::Base
  belongs_to :entry
  belongs_to :place
end
