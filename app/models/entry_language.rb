class EntryLanguage < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :entry
  belongs_to :language, counter_cache: :entries_count

  validates_presence_of :entry
  validate :observed_or_authority

  def display_value
    [language ? language.name : nil, observed_name ? "(#{observed_name})" : nil, certainty_flags].reject(&:blank?).join(" ")
  end

  def facet_value
    language ? language.name : nil
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

  private

  def observed_or_authority
    if observed_name.blank? && language.blank?
      errors[:base] << "Either an observed value or authority name are required (or both)"
    end
  end

end
