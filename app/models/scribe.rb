class Scribe < ActiveRecord::Base
  include UserFields

  def to_s
    name
  end

end
