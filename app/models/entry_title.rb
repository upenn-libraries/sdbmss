class EntryTitle < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry

  validates_presence_of :entry

  def display_value
    (title || "") + (common_title.present? ? " [#{common_title}]" : "") + certainty_flags
  end

  def to_s
    display_value
  end

end
