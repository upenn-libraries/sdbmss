class Download < ActiveRecord::Base
  belongs_to :user

  def to_s
    filename
  end

end