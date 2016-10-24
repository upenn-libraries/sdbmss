
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
    # NOTE: update_multiple is not a 'standard' Rails REST action, we
    # follow our own conventions on how it works
    base.after_action :log_activity, only: [:create, :update, :update_multiple, :destroy]
  end

  def log_activity
    if [200, 302].include?(status)
      model_name = controller_name.singularize

      if action_name == 'update_multiple'
        model_objects = instance_variable_get("@#{controller_name}") || []
        puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        puts model_objects
        puts "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        model_objects.each do |model_object|
          make_entry = true
          if model_object.destroyed?
            event = "destroy"
          elsif model_object.previous_changes["id"] && model_object.previous_changes["id"][0].nil?
            # new object
            event = "create"
          else
            # update
            event = "update"
            # only create an Activity record if updates were made
            make_entry = false if model_object.previous_changes.count == 0
          end
          if make_entry
            model_object.try(:create_activity, event, current_user, @transaction_id)
          end
        end
      else
        # in most cases, model object will be an instance var named
        # after the model (following the Rails convention), but for
        # controllers that inherit from ManageModelsController, it will
        # be called @model.
        model_object = instance_variable_get("@#{model_name.downcase}") || instance_variable_get("@model")

        if model_object.present?
          model_object.try(:create_activity, action_name, current_user, @transaction_id)
        else
          Rails.logger.error "Couldn't save Activity object in after_action hook for #{self.class}##{action_name}), no model object found"
        end
      end
    end
  end

end
