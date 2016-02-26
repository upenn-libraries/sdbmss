module Revert

  def revert
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