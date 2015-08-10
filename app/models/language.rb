class Language < ActiveRecord::Base

  default_scope { where(deleted: false) }

  has_many :entry_languages
  has_many :entries, through: :entry_languages

  include UserFields
  include ReviewedByField
  include IndexAfterUpdate
  include HasPaperTrail
  include CreatesActivity

  validates_presence_of :name

  def entries_to_index_on_update
    Entry.with_associations.joins(:entry_languages).where({ entry_languages: { language_id: id} })
  end

  def to_s
    name
  end

end
