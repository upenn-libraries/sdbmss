class Group < ActiveRecord::Base

  has_many :group_records, dependent: :destroy
  has_many :entries, through: :group_records, source: :record, source_type: "Entry"

  has_many :group_users, dependent: :destroy
  has_many :users, through: :group_users

  has_many :comments, as: :commentable

  accepts_nested_attributes_for :group_users, allow_destroy: true

  include UserFields

  def admin
    users.joins(:group_users).where(:group_users => {:role => "Admin", :confirmed => true}).distinct
  end

  def members
    users.joins(:group_users).where(:group_users => {:role => "Member", :confirmed => true}).distinct
  end

  def public_id
    "SDBM_GROUP_#{id}"
  end

  def preview
    %(
      <h4>#{name} - <small>#{public_id}</small></h4>
      <p>This group has #{users.count} members and is responsible for #{entries.count} entries.</p>
    )
  end

end