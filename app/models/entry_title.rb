class EntryTitle < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :entry

  validates_presence_of :entry

  before_save(on: :update) do |variable|
    puts "Hello! #{self.as_json}, #{variable.as_json}"
  end

  def display_value
    (title || "") + (common_title.present? ? " [#{common_title}]" : "") + certainty_flags
  end

  def to_s
    display_value
  end

  def to_fields
    {title: title, common_title: common_title}
  end

end
