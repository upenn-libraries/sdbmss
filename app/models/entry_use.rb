class EntryUse < ActiveRecord::Base
  belongs_to :entry

  validates_presence_of :entry
  validates_presence_of :use

  has_paper_trail skip: [:created_at, :updated_at]

end
