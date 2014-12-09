class Place < ActiveRecord::Base
  belongs_to :entry
  belongs_to :approved_by, :class_name => 'User'
end
