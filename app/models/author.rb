class Author < ActiveRecord::Base
  belongs_to :entry
  belongs_to :approved_by, :class_name => 'User'

  has_many :entry_authors
  has_many :entries, through: :entry_authors

  def get_public_id
    "SDBM_AUTHOR_#{id}"
  end

end
