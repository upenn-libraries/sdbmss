class Language < ActiveRecord::Base

  default_scope { where(deleted: false) }

  belongs_to :entry

  has_many :entry_languages
  has_many :entries, through: :entry_languages

  include UserFields
  include ReviewedByField

  validates_presence_of :name

  def to_s
    name
  end

end
