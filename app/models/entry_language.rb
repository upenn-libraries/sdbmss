class EntryLanguage < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :language

  def to_s
    (language ? language.name : "") + certainty_flags
  end

end
