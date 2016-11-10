class Watch < ActiveRecord::Base

  belongs_to :watched, polymorphic: true
  belongs_to :user

end