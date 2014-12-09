class EntryManuscript < ActiveRecord::Base
  belongs_to :entry
  belongs_to :manuscript
end
