class EntryLanguage < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :entry
  belongs_to :language, counter_cache: :entries_count

  validates_presence_of :entry
  validates_presence_of :language

  def display_value
    [language ? language.name : nil, observed_name ? "(#{observed_name})" : nil, certainty_flags].reject(&:blank?).join(" ")
  end

  def to_s
    display_value
  end

  def name_authority
    (language ? "<a href='/languages/#{language_id}'>#{language}</a> " : "")
  end

  def observed
    ""
  end

end
