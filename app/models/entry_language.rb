class EntryLanguage < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :entry
  belongs_to :language, counter_cache: :entries_count

  validates_presence_of :entry
  validates_presence_of :language

  def to_s
    (language ? language.name : "") + certainty_flags
  end

  def name_authority
    (language ? "<a href='/languages/#{language_id}'>#{language}</a> " : "")
  end

  def observed
    ""
  end

end
