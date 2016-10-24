
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
  belongs_to :item, polymorphic: true

  validates_presence_of :item_type
  validates_presence_of :item_id
  validates_presence_of :event

  scope :created_between, lambda {|start_date, end_date| where("created_at >= ? AND created_at <= ?", start_date, end_date )}

  # hide the 'rails-y' terminology
  def format_event
    if event == 'destroy'
      'deleted'
    elsif event == 'update'
      'edited'
    elsif event == 'create'
      'added'
    elsif event == 'mark_as_reviewed'
      'marked as reviewed'
    elsif event == 'merge'
      'merged'
    else
      event
    end
  end

  def link
    if item_type == 'User'
      "/accounts/#{item.id}"
    elsif item_type == 'EntryManuscript'
      "/manuscripts/#{item.manuscript.id}"
    else
      "/#{item.class.to_s.underscore.pluralize}/#{item.id}"
    end
  end

end
