class EntryPlace < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :place

  def to_s
    (place.name || "") + certainty_flags
  end

end
