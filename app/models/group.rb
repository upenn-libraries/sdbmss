class Group < ActiveRecord::Base

  has_many :group_records, dependent: :destroy
  has_many :entries, through: :group_records, source: :record, source_type: "Entry"

  has_many :group_users, dependent: :destroy
  has_many :users, through: :group_users

  has_many :comments, as: :commentable

  include UserFields

  def public_id
    "SDBM_GROUP_#{id}"
  end

end