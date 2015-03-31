class EntryPlace < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :place, counter_cache: :entries_count

  validates_presence_of :entry
  validates_presence_of :place

  has_paper_trail skip: [:created_at, :updated_at]

  def to_s
    (place.name || "") + certainty_flags
  end

end
