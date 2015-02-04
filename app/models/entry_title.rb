class EntryTitle < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry

  def to_s
    (title || "") + (common_title ? " [#{common_title}]" : "") + certainty_flags
  end

end
