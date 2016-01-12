
# Mix-in for models that should be able to create an Activity object
# representing the creation/update/deletion that has occurred to it.
module CreatesActivity

  def create_activity(action_name, current_user)
    activity = Activity.new(
      item_type: self.class.to_s,
      item_id: id,
      event: action_name,
      user_id: current_user.id
    )
    success = activity.save
    if !success
      Rails.logger.error "Error saving Activity object (): #{activity.errors.messages}"
    end
    activity
  end

end
