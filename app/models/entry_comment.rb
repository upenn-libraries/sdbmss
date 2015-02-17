class EntryComment < ActiveRecord::Base
  belongs_to :entry

  validates_presence_of :entry

  include UserFields

end
