class EntryComment < ActiveRecord::Base
  belongs_to :entry
  belongs_to :added_by, :class_name => 'User'
end
