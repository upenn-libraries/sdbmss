
# Provides action method #calculate_bounds for calculating the lower
# and upper bounds for a Jump To Search
module CalculateBounds

  # Provides action method #calculate_bounds for calculating the lower
  # and upper bounds for a Jump To Search
  def calculate_bounds
    clazz = controller_name.singularize.camelize.constantize

    per_page = params['per_page'].to_i
    id = params['id'].to_i
    if per_page.present? && id.present?

      offset = per_page / 2

      lower = clazz.where("id < ? ", id).order(id: :desc).offset(offset - 1).limit(1).first
      lower_id = lower.present? ? lower.id : 1
      upper = clazz.where("id > ? ", id).order(id: :asc).offset(offset - 2).limit(1).first
      upper_id = upper.present? ? upper.id : clazz.maximum(:id)

      respond_to do |format|
        format.json { render :json => { 'lower_bound' => lower_id, 'upper_bound' => upper_id }, :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { 'error' => 'per_page, id required' }, :status => :unprocessable_entity }
      end
    end
  end

end
