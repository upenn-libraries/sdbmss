class EntryUse < ActiveRecord::Base
  belongs_to :entry

  validates_presence_of :entry
  validates_presence_of :use

  include HasPaperTrail

  def to_fields
    {use: use}
  end

end
