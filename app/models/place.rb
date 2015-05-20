class Place < ActiveRecord::Base

  include UserFields
  include ReviewedByField
  include IndexAfterUpdate

  default_scope { where(deleted: false) }

  belongs_to :entry

  belongs_to :approved_by, :class_name => 'User'

  has_many :entry_places
  has_many :entries, through: :entry_places

  validates_presence_of :name

  def entries_to_index_on_update
    Entry.with_associations.joins(:entry_places).where({ entry_places: { place_id: id} })
  end

  def to_s
    name
  end

end
