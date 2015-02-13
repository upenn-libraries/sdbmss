class Place < ActiveRecord::Base
  belongs_to :entry

  include UserFields

  belongs_to :approved_by, :class_name => 'User'

  def to_s
    name
  end

end
