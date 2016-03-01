module Revert

  def revert
    @model = self.model_class.find(params[:id])
    @version = PaperTrail::Version.find(params[:version_id])
    item_type = @version.item_type

    # SIMPLE FIELD CHANGE
    if item_type == @model.model_name.name
      @changeset = @version.changeset
    
    # ASSOCIATED FIELD CHANGE (e.g. entry_title)
    else
      @overwrite = params[:overwrite].present? ? params[:overwrite] == 'true' : false   # option to overwrite field if they share an ID
      @current = @model.send(item_type.underscore.pluralize)  # current list of associations
      
      changed = @version.reify(dup: true)                    # the associated record as it WAS (for all but undo-create)
      if @version.event == 'create'
        changed = @current.find(@version.item_id)
      end

      @changed_fields = changed.to_fields
      @changed_attr = changed.attributes

      if @version.event == 'create'
        @changed_attr[:_destroy] = 1
        @overwrite = true
      end

      # to force creating a new associated record, we remove the 'id' field
      if !@overwrite || !item_type.singularize.classify.constantize.find(@version.item_id).present?
        @changed_attr.present? ? @changed_attr[:id] = nil : ''
        @msg = 'The corresponding field has been deleted, would you like to recreate it?' unless @version.event == 'create'
      end
    end
    render :template => 'shared/revert'
  end

end