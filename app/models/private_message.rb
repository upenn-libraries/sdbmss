class PrivateMessage < ActiveRecord::Base

  default_scope { where(deleted: false) }

  include UserFields

  belongs_to :users
  belongs_to :private_messages

  validates_presence_of :message
  validates_presence_of :user_id

end