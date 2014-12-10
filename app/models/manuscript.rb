class Manuscript < ActiveRecord::Base

  has_many :entry_manuscripts
  has_many :entries, through: :entry_manuscripts

end
