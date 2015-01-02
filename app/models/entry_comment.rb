class EntryComment < ActiveRecord::Base
  belongs_to :entry
  belongs_to :created_by, :class_name => 'User'
end
