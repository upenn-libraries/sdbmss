class EntryManuscript < ActiveRecord::Base
  belongs_to :entry
  belongs_to :manuscript

  validates_presence_of :relation_type

  TYPE_RELATION_IS = 'is'
  TYPE_RELATION_PARTIAL = 'partial'
  TYPE_RELATION_POSSIBLE = 'possible'

end
