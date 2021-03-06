
# Provides #mark_as_reviewed action that accepts an object with key
# 'ids' whose value is an array of entity ids.
module MarkAsReviewed

  extend ActiveSupport::Concern

  def self.included(base)
    if !base.method_defined?(:model_class)
      raise "method #model_class not found in base class that's trying to include MarkAsReviewed"
    end
  end

  def mark_as_reviewed
    ids = params[:ids]
    if ids.present?
      ids = ids.map(&:to_i)
      model_class.where('id IN (?)', ids).each do |model|
        ActiveRecord::Base.transaction do  
          model.update(reviewed: true, reviewed_by_id: current_user.id, reviewed_at: DateTime.now)
          model.delay.index
          @transaction_id = PaperTrail.transaction_id
          @model = model
          if defined? log_activity
            log_activity
          end
        end
      end
    end
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
    end
  end

end
