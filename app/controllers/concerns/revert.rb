module Revert

  def revert
    @model = self.model_class.find(params[:id])
    @version = PaperTrail::Version.find(params[:version_id])
    item_type = @version.item_type
    if item_type == @model.model_name.name
    # if the change is NOT to an association
      @changeset = @version.changeset
    else
    # for changes to associations
      @current = @model.send(item_type.underscore.pluralize)
      @changed = @version.reify(dup: true)
      @overwrite = false
      @current.each do |c|
        if c.id == @changed.id
          @overwrite = false
          break
        end
      end
      @overwrite = params[:overwrite].present? ? params[:overwrite] == 'true' : @overwrite
    end
    if !@overwrite
      @changed[:id] = nil
    end
    render :template => 'shared/revert'
  end

  def revert_old
    @model = self.model_class.find(params[:id])
    @version = PaperTrail::Version.find(params[:version_id])
    if @version.event == 'destroy'
      version_changeset = {}
      version_attributes = @version.reify(dup: true).attributes
      version_attributes.each do |f, v|
        if version_attributes[f] && !version_attributes.blank?
          version_changeset[f] = [v, nil]
        end
      end
    end
    @changes = @version.event == 'create' ? {_destroy: 1} : @version.reify(dup: true).attributes
    @changeset = @version.changeset.blank? ? version_changeset : @version.changeset
    begin
      @current = @version.item_type.singularize.classify.constantize.find(@version.item_id)
    rescue ActiveRecord::RecordNotFound
      @current = {}
      @changes[:id] = nil
      if @version.event == 'update'
        @msg = "Warning: That field no longer exists - would you like to recreate it?"
      elsif @version.event == 'create'
        @msg = "Warning: That field has already been destroyed.  No change is possible."
      end
    else
      if @version.event == 'destroy'
        @changes[:id] = nil
      elsif @version.event == 'create'
        @changes = @current.attributes
        @changes[:_destroy] = 1
      end
    end
    render :template => 'shared/revert'
  end


end