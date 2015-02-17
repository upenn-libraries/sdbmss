class Scribe < ActiveRecord::Base
  include UserFields

  validates_presence_of :name

  def to_s
    name
  end

end
