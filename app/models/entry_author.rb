class EntryAuthor < ActiveRecord::Base
  belongs_to :entry
  belongs_to :author
end
