class Language < ActiveRecord::Base
  belongs_to :entry

  include UserFields

end
