class Watch < ApplicationRecord

  belongs_to :watched, polymorphic: true
  belongs_to :user

  validates :user_id, uniqueness: { 
    scope: [:watched_id, :watched_type],
    message: "you can only watch a record once"
  }

end