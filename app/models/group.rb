class Group < ActiveRecord::Base

  has_many :group_records
  has_many :entries, through: :group_records, source: :record, source_type: "Entry"

  has_many :group_users
  has_many :users, through: :group_users

  include UserFields

end