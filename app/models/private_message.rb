class PrivateMessage < ActiveRecord::Base

  default_scope { where(deleted: false) }

  include UserFields
  include Notified
  
  has_many :user_messages, foreign_key: "private_message_id"
  has_many :users, through: :user_messages

  belongs_to :private_message

  accepts_nested_attributes_for :user_messages

  scope :sent, -> () { joins(:user_messages).where("user_messages.method = 'From'").distinct }
  scope :received, -> () { joins(:user_messages).where("user_messages.method = 'To'").distinct }

  validates_presence_of :message
  validates_presence_of :title

  def sent_by
    users.sent_by
  end

  def sent_to
    users.sent_to
  end

  # used, at the moment, for notifications only
  def preview
    %(<blockquote><b>#{title}</b>
      #{message.at(0..100)}#{message.length > 100 ? '...' : ''}</blockquote> )
  end

end