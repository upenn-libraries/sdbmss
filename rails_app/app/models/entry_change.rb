
# These are migrated legacy records of changes made to (what were
# called) Manuscript records.
class EntryChange < ActiveRecord::Base
  belongs_to :entry
  belongs_to :changed_by, :class_name => 'User'

  validates_presence_of :entry
end