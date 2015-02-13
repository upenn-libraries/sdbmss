class Language < ActiveRecord::Base
  belongs_to :entry

  include UserFields

  def to_s
    name
  end

end
