class PrivateMessage < ActiveRecord::Base

  default_scope { where(deleted: false) }

  include UserFields

  belongs_to :user
  belongs_to :private_message

  has_many :private_messages

  validates_presence_of :message
  validates_presence_of :user_id

  def children
    private_messages
  end

  def parent
    private_message
  end

end