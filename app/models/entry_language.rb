class EntryLanguage < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :language

  validates_presence_of :entry
  validates_presence_of :language

  def to_s
    (language ? language.name : "") + certainty_flags
  end

end
