class NamePlace < ActiveRecord::Base

  belongs_to :name
  belongs_to :place

  validates_presence_of :place

end