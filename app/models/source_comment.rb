
class SourceComment < ActiveRecord::Base
  belongs_to :source
  belongs_to :comment
  validates_presence_of :source
  validates_presence_of :comment

  accepts_nested_attributes_for :comment, allow_destroy: true

  include HasPaperTrail
end
