
# Code for reconciling an ActiveRecord object's associations (ie
# database joins) against incoming data, typically from an HTTP
# request.
module Reconciler

  # module-level methods
  class << self

    # Reconciles 1-M (parent-children) records
    #
    # parent = object containing the many
    # incoming = array of hashes representing records to be reconciled against db
    # child_model_name = constant for the activerecord model for child records
    # fk_name = name of parent FK field on child record
    # attributes = array of symbols to use for persisting model from 'incoming' data struct
    #
    # if a block is given, it gets run as a callback after each
    # insert/update. This handles nested data structures.
    def reconcile_assoc parent, incoming, child_model_name, fk_name, attributes, &block
      ids_persisted = []
      incoming = [] if incoming.blank?
      incoming.each do |model_params|
        model_obj = model_params['id'].present? ? child_model_name.find(model_params['id']) : child_model_name.new(fk_name => parent.id)
        model_obj.assign_attributes(model_params.permit(*attributes))
        model_obj.save!
        ids_persisted << model_obj.id

        block.call(model_obj, model_params) if block_given?
      end

      # TODO: be more careful here: the records to delete should
      # probably be marked, instead of deleting the remaining records
      # in this way

      delete_query = child_model_name.where(fk_name => parent)
      if !ids_persisted.blank?
        delete_query = delete_query.where("id not in (?)", ids_persisted)
      end
      delete_query.destroy_all
    end

  end

end
