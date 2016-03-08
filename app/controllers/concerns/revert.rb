module Revert

  def revert
    @model = self.model_class.find(params[:id])

    if params[:version_id].kind_of? Array
      @versions = []
      params[:version_id].each { |vid| @versions.append(PaperTrail::Version.find(vid)) }
    else
      @versions = [PaperTrail::Version.find(params[:version_id])]
    end

    touched = []
    ActiveRecord::Base.transaction do

      @versions.each do |version|
        if version.reify
          v = version.reify
          v.save!
        else
          v = version.item
          v.destroy
        end
        if v.model_name.name != @model.model_name.name
          e = v.send @model.model_name.name.underscore
          if not touched.include? e
            e.touch
            touched.append(e)
          end
        end
      end

      touched.each do |t|
        t.save
      end
    end
    
    redirect_to polymorphic_path(@model)
  end

  def revert_confirm
    @model = self.model_class.find(params[:id])

    if params[:version_id].kind_of? Array
      @versions = []
      params[:version_id].each { |vid| @versions.append(PaperTrail::Version.find(vid)) }
    else
      @versions = [PaperTrail::Version.find(params[:version_id])]
    end

    @changes = []
    @currents = []

    @versions.each do |version|
      version_class = version.item_type.singularize.classify.constantize
      if version.event == 'destroy'   #undelete
        if version_class.exists? version.item_id
          @error = "You cannot un-delete this field, it already exists!"
        else
          current = "Deleted"
          v = version.reify(dup: true)
          @currents.append({})
          diff = {}
          v.attributes.each { |f, val| diff[f] = ['(blank)', val ] if val }
          @changes.append({diff: diff, attr: v.attributes, model_name: v.model_name.name})
          # need to recreate a record with the same id... 
        end
      elsif version.event == 'create' #uncreate
        if !version_class.exists? version.item_id
          @error = "You cannot un-create this field, it does not exist!"
        else

        end
      elsif version.event == 'update' #update
        # whether it exists or doesn't exist, restore/overwrite it!
        if !version_class.exists? version.item_id
          # need to recreate w/ same id (again)
        else
          current = version_class.find(version.item_id)
          v = version.reify(dup: true)
          diff = {}
          a = current.attributes
          b = v.attributes
          a.each { |f, v| diff[f] = [v, b[f]] if b[f] && b[f] != v }

          @currents.append(diff)
          @changes.append({diff: diff, attr: b, model_name: v.model_name.name})
        end
      end
    end
    render :template => 'shared/revert'
  end

end