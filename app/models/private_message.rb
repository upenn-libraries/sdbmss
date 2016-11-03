class PrivateMessage < ActiveRecord::Base

  default_scope { where(deleted: false) }

  include UserFields
  include Notified
  
  has_many :user_messages, -> { where(:deleted => false) }, foreign_key: "private_message_id", dependent: :destroy
  has_many :users, through: :user_messages

  belongs_to :private_message
  has_many :replies, foreign_key: "private_message_id", class_name: "PrivateMessage"

  accepts_nested_attributes_for :user_messages

  validates_presence_of :message
  validates_presence_of :title

  def sent_by
    created_by || user_messages.where(method: "From").first.user
  end

  def sent_to
    users
  end

  def unread(user)
    um = user_messages.where(user_id: user.id).first
    if um
      um.unread
    else
      false
    end
  end

  def read(user)
    um = user_messages.where(user_id: user.id).first
    if um
      um.update(unread: false)
    else
      false
    end
  end

  # used, at the moment, for notifications only
  def preview
    %(<blockquote><b>#{title}</b>
      #{message.at(0..100)}#{message.length > 100 ? '...' : ''}</blockquote> )
  end

end