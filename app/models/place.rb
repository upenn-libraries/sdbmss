class Place < ActiveRecord::Base

  default_scope { where(deleted: false) }

  belongs_to :entry

  has_many :entry_places
  has_many :entries, through: :entry_places

  include UserFields

  belongs_to :approved_by, :class_name => 'User'

  validates_presence_of :name

  def to_s
    name
  end

end
