
class NameComment < ActiveRecord::Base
  belongs_to :name
  belongs_to :comment
  validates_presence_of :name
  validates_presence_of :comment

  accepts_nested_attributes_for :comment, allow_destroy: true

  include HasPaperTrail
end
