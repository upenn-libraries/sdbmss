
# Activities are events that occur in the system, usually (but not
# limited to) create/update/destroy events.
#
# This model exists because we need a way to represent changes that
# occur at a higher level than row-level changes in table, which are
# recorded using PaperTrail. For example, changing the author info for
# an Entry entails changing EntryAuthor records, but from a user
# standpoint, it's the Entry that has changed, and that's what we
# would record here in the Activity.
class Activity < ActiveRecord::Base

  belongs_to :user

  validates_presence_of :item_type
  validates_presence_of :item_id
  validates_presence_of :event

end
