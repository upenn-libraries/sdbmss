class Place < ActiveRecord::Base

  default_scope { where(deleted: false) }

  belongs_to :entry

  has_many :entry_places
  has_many :entries, through: :entry_places

  include UserFields
  include ReviewedByField
  include IndexAfterUpdate

  belongs_to :approved_by, :class_name => 'User'

  validates_presence_of :name

  def entries_to_index_on_update
    Entry.with_associations.joins(:entry_places).where({ entry_places: { place_id: id} })
  end

  def to_s
    name
  end

end
