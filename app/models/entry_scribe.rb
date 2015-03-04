class EntryScribe < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :scribe, class_name: 'Name', counter_cache: :scribes_count

  validates_presence_of :entry

  def to_s
    (scribe ? scribe.name : "") + certainty_flags
  end

end
