
# Note that we treat this as a "first-class" entity, similar to Entry
# or Source, even though it is a join record. This should probably be
# renamed to something like EntryLink.
class EntryManuscript < ActiveRecord::Base
  belongs_to :entry
  belongs_to :manuscript, counter_cache: :entries_count

  validates_presence_of :entry
  validates_presence_of :manuscript
  validates_presence_of :relation_type

  TYPE_RELATION_IS = 'is'
  TYPE_RELATION_PARTIAL = 'partial'
  TYPE_RELATION_POSSIBLE = 'possible'

  include UserFields
  include HasPaperTrail
  include CreatesActivity

  def create_activity(action_name, current_user)
    activity = super
    em_activity = EntryManuscriptActivity.new(
      activity: activity,
      entry_id: entry_id,
      manuscript_id: manuscript_id,
    )
    success = em_activity.save
    if !success
      Rails.logger.error "Error saving EntryManuscriptActivity object: #{em_activity.errors.messages}"
    end
    activity
  end

end
