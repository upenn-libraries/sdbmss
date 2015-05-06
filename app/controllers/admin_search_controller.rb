
# Treat Admin search screen as a specialized case of a
# CatalogController so we can take advantage of its search
# functionality.
#
# Alternatively, we could tack this functionality directly into
# CatalogController, but AdminSearchController gives us our own view
# directory for overriding partials, which I think is probably useful.
class AdminSearchController < CatalogController

  before_action :authenticate_user!

  # Overrides Blacklight::Catalog#render_search_results_as_json to
  # provide search results in JSON format expected by datatables
  # widget, which is the only thing that uses (or should use) this,
  # since we return arrays instead of objects with more meaningful
  # keys.
  def render_search_results_as_json
    dateformat = "%Y-%m-%d %I:%M%P"
    row_error = ([nil] * 41).tap { |a| a[1]="Error loading" }
    retval = {
      draw: params[:draw],
    }
    begin
      pinfo = pagination_info(@response)

      data = @document_list.map do |doc|
        entry = doc.model_object
        !entry.nil? ? entry.as_flat_hash : {}
      end

      retval.merge!({
                      recordsTotal: pinfo[:total_count],
                      recordsFiltered: pinfo[:total_count],
                      data: data,
                    })
    rescue Exception => e
      puts e.backtrace
      retval.merge!({
                      error: e.to_s
                    })
    end
    retval
  end

  # Overrides Blacklight::Catalog::SearchContext#add_to_search_history
  def add_to_search_history search
    # this is a noop: prevent this controller's searches from being
    # saved, because that's confusing to end users.
  end

  # This is an AJAX endpoint to calculates the lower and upper bounds
  # (inclusive) on entry_id for a "Jump To" search.
  def calculate_bounds
    per_page = params['per_page'].to_i
    entry_id = params['entry_id'].to_i
    if per_page.present? && entry_id.present?

      offset = per_page / 2

      lower = Entry.where("id < ? ", entry_id).order(id: :desc).offset(offset - 1).limit(1).first
      lower_id = lower.present? ? lower.id : 1
      upper = Entry.where("id > ? ", entry_id).order(id: :asc).offset(offset - 2).limit(1).first
      upper_id = upper.present? ? upper.id : Entry.maximum(:id)

      respond_to do |format|
        format.json { render :json => { 'lower_bound' => lower_id, 'upper_bound' => upper_id }, :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { 'error' => 'per_page, entry_id required' }, :status => :unprocessable_entity }
      end
    end
  end

end
