class GroupRecord < ActiveRecord::Base
  belongs_to :record, polymorphic: true
  belongs_to :group

  validates_uniqueness_of :group_id, :scope => :record_id
end