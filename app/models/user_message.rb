class UserMessage < ActiveRecord::Base

  belongs_to :private_message
  belongs_to :user

end