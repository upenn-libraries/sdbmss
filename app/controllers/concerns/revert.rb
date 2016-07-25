module Revert

  def revert
    if !can? :edit, model_class
      flash[:error] = "You do not have permission to revert any changes for this record."
      redirect_to polymorphic_path(@model)
      return
    end

    @model = model_class.find(params[:id])

    if params[:version_id].kind_of? Array
      @versions = []
      params[:version_id].each { |vid| @versions.append(PaperTrail::Version.find(vid)) }
    else
      @versions = [PaperTrail::Version.find(params[:version_id])]
    end

    touched = []
    destroyed = false

    ActiveRecord::Base.transaction do

      @versions.each do |version|
        v = version.reify
        if v
          if version.event == 'destroy'
            v.created_at = Time.now
          end
          v.save
        else
          v = version.item
          v.destroy
          destroyed = true
        end
        if v.model_name.name != @model.model_name.name
          e = v.send @model.model_name.name.underscore
          if not touched.include? e
            e.touch_with_version
            touched.append(e)
          end
        end
      end

      touched.each do |t|
        t.save
      end
    end
    
    if destroyed
      redirect_to dashboard_path
    else
      redirect_to polymorphic_path(@model)
    end
  end

  def revert_confirm
    @model = model_class.find(params[:id])

    if params[:version_id].kind_of? Array
      @versions = []
      params[:version_id].each { |vid| @versions.append(PaperTrail::Version.find(vid)) }
    elsif not params.include? :version_id
      @versions = []
      @error = "No changes selected."
    else
      @versions = [PaperTrail::Version.find(params[:version_id])]
    end

    @changes = []

    @versions.each do |version|
      version_class = version.item_type.singularize.classify.constantize
      if version_class == @model.class && version.event == 'create'
        @error = "WARNING: If you undo creation of this record, it will be deleted and the change history will no longer be accessible."
      end
      
      if version.event == 'destroy'   #undelete
        if version.item
          @error = "You cannot un-delete this field, it already exists!"
        else
          v = version.reify(dup: true)
          change = reversion_format({}, v.attributes)
          change[:model_name] = v.model_name.name
        end
      elsif version.event == 'create' #uncreate
        if !version.item
          @error = "You cannot un-create this field, it does not exist!"
        else
          current = version.item
          change = reversion_format(current.attributes, {})
          change[:model_name] = current.model_name.name
        end
      elsif version.event == 'update' #update
        if !version.item
          v = version.reify(dup: true)
          change = reversion_format({}, v.attributes )
          change[:model_name] = v.model_name.name
        else
          current = version.item
          v = version.reify(dup: true)
          change = reversion_format(current.attributes, v.attributes)
          change[:model_name] = v.model_name.name
        end
      end
       @changes.append(change)
    end
    total_changes = []
    @changes.each { |c| total_changes += c[:fields] }
    if total_changes.count <= 0
      @error = "This reversion will not result in any change in information."
    end
    render :template => 'shared/revert'
  end

  def reversion_format (current, previous)

    # select only the fields that are changed between the two versions
    current2 = current.select { |field, value| value != nil && previous[field] != value }
    previous2 = previous.select { |field, value| value != nil && current[field] != value }
    
    # ignore fields that are skipped by paper-trail (or that shouldn't be shown)
    fields = ((current2.keys | previous2.keys) - @model.paper_trail_options[:ignore]) - ['id', 'entry_id', 'created_at']
    
    #substitute the name for the id for associated fields    
    current2.each do |k, v|
      if EntryVersionFormatter.isClass(k)
        current2[k] = "#{EntryVersionFormatter.toClass(k).find(v)}"
      end
    end

    previous2.each do |k, v|
      if EntryVersionFormatter.isClass(k)
        previous2[k] = "#{EntryVersionFormatter.toClass(k).find(v)}"
      end
    end

    change = {fields: fields, current: current2, previous: previous2}
    return change
  end

  def history
    @model = model_class.find(params[:id])
    if can?(:history, @model)
      @versions = @model.versions
      render :template => 'shared/history'
    else
      flash[:error] = "You do not have permission to view the history for this record."
      redirect_to polymorphic_path(@model)
    end
  end

end