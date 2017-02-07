class Rating < ActiveRecord::Base

  belongs_to :ratable, polymorphic: true
  belongs_to :user

  validates :user_id, uniqueness: { 
    scope: [:ratable_id, :ratable_type],
    message: "only one rating per user, per rating"
  }

end