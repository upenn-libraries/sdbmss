
class Activity < ActiveRecord::Base

  validates_presence_of :item_type
  validates_presence_of :item_id
  validates_presence_of :event

end
