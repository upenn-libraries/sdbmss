
class ManuscriptComment < ActiveRecord::Base
  belongs_to :manuscript

  validates_presence_of :manuscript

  include UserFields

end
