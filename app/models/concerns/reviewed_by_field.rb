
# A concern for model classes that have a reviewed_by field
module ReviewedByField

  extend ActiveSupport::Concern

  included do
    belongs_to :reviewed_by, class_name: 'User'
  end

end
