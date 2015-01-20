class Artist < ActiveRecord::Base
  belongs_to :entry

  include UserFields

  belongs_to :approved_by, :class_name => 'User'
end
