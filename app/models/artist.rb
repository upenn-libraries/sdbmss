class Artist < ActiveRecord::Base
  belongs_to :entry

  include UserFields

  belongs_to :approved_by, :class_name => 'User'

  validates_presence_of :name

  def to_s
    name
  end

end
