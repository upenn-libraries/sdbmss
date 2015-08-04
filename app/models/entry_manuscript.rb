class EntryManuscript < ActiveRecord::Base
  belongs_to :entry
  belongs_to :manuscript, counter_cache: :entries_count

  validates_presence_of :entry
  validates_presence_of :manuscript
  validates_presence_of :relation_type

  TYPE_RELATION_IS = 'is'
  TYPE_RELATION_PARTIAL = 'partial'
  TYPE_RELATION_POSSIBLE = 'possible'

  include HasPaperTrail
end
