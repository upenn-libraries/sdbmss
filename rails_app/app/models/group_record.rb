class GroupRecord < ActiveRecord::Base
  belongs_to :record, polymorphic: true, required: true
  belongs_to :group, required: true

  validates_uniqueness_of :group_id, :scope => :record_id
end