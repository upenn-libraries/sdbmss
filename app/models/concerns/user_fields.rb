
# A concern for model classes that have created_by and updated_by fields
module UserFields

  extend ActiveSupport::Concern

  included do

    belongs_to :created_by, class_name: 'User'

    belongs_to :updated_by, class_name: 'User'

  end

  def save_by(user, *args, &block)
    if !persisted?
      self.created_by = user
    end
    self.updated_by = user
    save(*args, &block)
  end

  def update_by(user, *args, &block)
    self.updated_by = user
    if self.created_by && self.created_by != user
      self.created_by.notify("One of your records has been updated by #{user.to_s}.", 
        #{}"#{user.to_s} has updated #{self.public_id}."
        self, "update")
    end
    update(*args, &block)
  end

end
