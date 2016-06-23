class PrivateMessage < ActiveRecord::Base

  default_scope { where(deleted: false) }

  include UserFields

  has_many :user_messages, foreign_key: "private_message_id"
  has_many :users, through: :user_messages

  accepts_nested_attributes_for :user_messages

  scope :sent, -> () { joins(:user_messages).where("user_messages.method = 'From'").distinct }
  scope :received, -> () { joins(:user_messages).where("user_messages.method = 'To'").distinct }

  validates_presence_of :message
  validates_presence_of :title

  def sent_by
    users.sent_by[0]
  end

  def sent_to
    users.sent_to[0]
  end

end