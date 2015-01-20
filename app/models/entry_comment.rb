class EntryComment < ActiveRecord::Base
  belongs_to :entry

  include UserFields

end
