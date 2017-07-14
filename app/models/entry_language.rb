class EntryLanguage < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :entry
  belongs_to :language, counter_cache: :entries_count

  validates_presence_of :entry
  validate :observed_or_authority

  def to_s
    (language ? language.name : observed_name.to_s) + certainty_flags
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
