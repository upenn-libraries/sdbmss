class UserMessage < ActiveRecord::Base

  belongs_to :private_message
  belongs_to :user

  def destroy
    update!(deleted: true)
  end

end