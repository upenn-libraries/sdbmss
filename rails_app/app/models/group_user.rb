class GroupUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  belongs_to :created_by, class_name: 'User'

  validates_uniqueness_of :group_id, :scope => :user_id
end