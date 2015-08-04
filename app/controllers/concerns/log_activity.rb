
# Registers a hook called after create, update, destroy actions, so
# that we can log that activity. We maintain this data separately from
# model-level changes (using PaperTrail) because:
#
# - It allows us to store custom events (non-CRUD operations)
#
# - Activity objects a are easily query-able since we don't need to
#  reconstruct/infer events from Paper Trail version associations.
#
module LogActivity

  extend ActiveSupport::Concern

  def self.included(base)
    base.after_action :log_activity, only: [:create, :update, :destroy]
  end

  def log_activity
    if status == 200
      model_name = controller_name.singularize.capitalize

      # in most cases, model object will be an instance var named
      # after the model (following the Rails convention), but for
      # controllers that inherit from ManageModelsController, it will
      # be called @model.
      model_object = instance_variable_get("@#{model_name.downcase}") || instance_variable_get("@model")

      if model_object.present?
        activity = Activity.new(
          item_type: model_name,
          item_id: model_object.id,
          event: action_name,
          user_id: current_user.id
        )
        success = activity.save
        if !success
          Rails.logger.error "Error saving Activity object (#{controller_name}): #{activity.errors.messages}"
        end
      else
        Rails.logger.error "Couldn't save Activity object (#{controller_name}), missing model object"
      end
    end
  end

end
