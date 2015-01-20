
# A concern for model classes that have created_by and updated_by fields
module UserFields

  extend ActiveSupport::Concern

  included do

    belongs_to :created_by, class_name: 'User'

    belongs_to :updated_by, class_name: 'User'

  end

end
