
# fix me: no longer used, remove?

# For controllers that need to reset 'reviewed' flag on a model object
# after the #update action is finished. This is safe to include on a
# resource controller whose model doesn't have a 'reviewed' flag, in
# which case, this concern has no effect.
module ResetReviewedAfterUpdate

  extend ActiveSupport::Concern

  def self.included(base)
    base.after_action :reset_reviewed_after_update, only: [:update]
  end

  def reset_reviewed_after_update
    if model_object_for_reset_reviewed_after_update.class.column_names.include?("reviewed")
      if respond_to?(:model_object_for_reset_reviewed_after_update)
        model_object_for_reset_reviewed_after_update.update(reviewed: false)
      else
        raise "method #model_object_for_reset_reviewed_after_update not found in #{self.class} that included ResetReviewedAfterUpdate"
      end
    end
  end

end
