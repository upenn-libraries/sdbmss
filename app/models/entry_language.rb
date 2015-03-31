class EntryLanguage < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :language, counter_cache: :entries_count

  validates_presence_of :entry
  validates_presence_of :language

  has_paper_trail skip: [:created_at, :updated_at]

  def to_s
    (language ? language.name : "") + certainty_flags
  end

end
