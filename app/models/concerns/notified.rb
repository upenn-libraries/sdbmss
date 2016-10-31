# mixin to create relationship between records that 'notify' the user and the notification

module Notified

  extend ActiveSupport::Concern

  included do

    has_many :notifications, as: :notified

  end

  def preview
    "<blockquote>#{public_id}</blockquote>"
  end

end