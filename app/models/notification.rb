class Notification < ActiveRecord::Base
  belongs_to :user

  belongs_to :notified, polymorphic: true
end
