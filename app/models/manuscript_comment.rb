
class ManuscriptComment < ActiveRecord::Base
  belongs_to :manuscript
  belongs_to :comment
  validates_presence_of :manuscript
  validates_presence_of :comment

  include HasPaperTrail
end
