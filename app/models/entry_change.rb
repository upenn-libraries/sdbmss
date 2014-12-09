class EntryChange < ActiveRecord::Base
  belongs_to :entry
  belongs_to :changed_by, :class_name => 'User'
end
