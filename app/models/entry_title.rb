class EntryTitle < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry

  validates_presence_of :entry

  def to_s
    (title || "") + (common_title.present? ? " [#{common_title}]" : "") + certainty_flags
  end

end
