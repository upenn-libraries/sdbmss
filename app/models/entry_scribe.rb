class EntryScribe < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :scribe

  def to_s
    (scribe ? scribe.name : "") + certainty_flags
  end

end
