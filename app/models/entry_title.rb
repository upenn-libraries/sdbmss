class EntryTitle < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :entry

  validates_presence_of :entry
  validates_length_of :title, :minimum => 0, :maximum => 255, :allow_blank => true

  def display_value
    [title, common_title ? "(#{common_title})" : nil, certainty_flags].reject(&:blank?).join(" ")
  end

  # fix me: what is the best value for faceting? 
  def facet_value
    common_title ? common_title : title
  end

  def to_s
    display_value
  end

  def to_fields
    {title: title, common_title: common_title}
  end

end
