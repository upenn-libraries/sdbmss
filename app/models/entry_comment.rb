class EntryComment < ActiveRecord::Base
  belongs_to :entry
  belongs_to :comment
  validates_presence_of :entry
  validates_presence_of :comment

  include HasPaperTrail

end
