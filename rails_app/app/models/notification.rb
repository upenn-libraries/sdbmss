class Notification < ApplicationRecord
  belongs_to :user

  belongs_to :notified, polymorphic: true
end
