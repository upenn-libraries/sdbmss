class Language < ActiveRecord::Base
  belongs_to :entry

  include UserFields

  validates_presence_of :name

  def to_s
    name
  end

end
