class GroupUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  validates_uniqueness_of :group_id, :scope => :user_id
end