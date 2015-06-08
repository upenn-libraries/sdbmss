
class Comment < ActiveRecord::Base

  default_scope { where(deleted: false) }

  scope :with_associations, -> {
    includes(
      [
        :entries,
        :manuscripts,
        :created_by
      ]
    )
  }

  # returns the comments on all Entries created by passed-in User
  scope :with_entries_belonging_to, ->(user) { joins(:entries).where(entries: { created_by: user }).order(created_at: :desc) }

  has_many :entry_comments
  has_many :entries, through: :entry_comments

  has_many :manuscript_comments
  has_many :manuscripts, through: :manuscript_comments

  include UserFields

  def entry
    entries.first
  end

  def manuscript
    manuscripts.first
  end

  # returns the model object to which this comment pertains
  def subject
    entry || manuscript
  end

end
