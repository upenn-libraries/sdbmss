
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

end
