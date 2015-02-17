class EntryScribe < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :scribe

  validates_presence_of :entry
  validates_presence_of :scribe

  def to_s
    (scribe ? scribe.name : "") + certainty_flags
  end

end
