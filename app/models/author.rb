class Author < ActiveRecord::Base
  belongs_to :entry

  include UserFields

  belongs_to :approved_by, :class_name => 'User'

  has_many :entry_authors
  has_many :entries, through: :entry_authors

  validates_presence_of :name

  def get_public_id
    "SDBM_AUTHOR_#{id}"
  end

  def to_s
    name
  end

end
