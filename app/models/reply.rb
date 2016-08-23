class Reply < ActiveRecord::Base
  belongs_to :comment

  include UserFields
end
