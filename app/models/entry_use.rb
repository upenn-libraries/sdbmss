class EntryUse < ActiveRecord::Base
  belongs_to :entry

  validates_presence_of :entry
  validates_presence_of :use
  validates_length_of :use, :minimum => 0, :maximum => 255, :allow_blank => true

  include HasPaperTrail

  def to_fields
    {use: use}
  end

end
