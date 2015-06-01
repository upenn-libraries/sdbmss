
# This is a subclass of CatalogController so we can take advantage of
# the search functionality in the #index action for the table view of
# Entries.
class EntriesController < CatalogController

  before_action :set_entry, only: [:show, :show_json, :edit, :update, :destroy, :similar, :history]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :similar, :mark_as_approved]

  respond_to :html, :json

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_approved]

  # JSON data structure optimized for editing page. This weird action
  # exists because we want CatalogController to handle #show, but we
  # want to format the JSON differently from how it does it.
  def show_json
    respond_to do |format|
      format.json { render "show.json" }
    end
  end

  # Overrides Blacklight::Catalog#render_search_results_as_json to
  # provide search results in JSON format expected by datatables
  # widget, which is the only thing that uses (or should use) this,
  # since we return arrays instead of objects with more meaningful
  # keys.
  def render_search_results_as_json
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

  def new
    @entry = Entry.new
    @source_id = params[:source_id]
    if @source_id.present?
      respond_to do |format|
        format.html { render "edit" }
      end
    else
      respond_to do |format|
        format.html { render "select_source" }
      end
    end
  end

  def create
    ActiveRecord::Base.transaction do
      filtered = entry_params_for_create_and_edit
      @entry = Entry.new(filtered)
      @entry.created_by_id = current_user.id
      @entry.source_id = params[:source_id]
      @entry.save!

      if params[:new_comment].present?
        ec = EntryComment.new(
          entry_id: @entry.id,
          comment_attributes: {
            comment: params[:new_comment],
            created_by_id: current_user.id
          })
        ec.save!
      end
    end
    render "show"
  end

  def edit
    expires_now
  end

  def update
    errors = nil
    begin
      if params[:cumulative_updated_at].to_s == @entry.cumulative_updated_at.to_s

        ActiveRecord::Base.transaction do
          filtered = entry_params_for_create_and_edit
          @entry.update!(filtered)

          if params[:new_comment].present?
            ec = EntryComment.new(
              entry_id: @entry.id,
              comment_attributes: {
                comment: params[:new_comment],
                created_by: current_user
              })
            ec.save!
          end
        end

      else
        errors = "Another change was made to the record while you were working. Re-load the page and start over."
      end

    rescue Exception => e
      logger.error(e.to_s + "\n\n" + e.backtrace.join("\n"))
      errors = e.backtrace.to_s
    end

    if errors
      render :json => { :errors => errors }, :status => :unprocessable_entity
    else
      render "show"
    end
  end

  # returns JSON containing type constants
  def types
    data = {
      'transaction_type' => Entry::TYPES_TRANSACTION,
      'author_role' => EntryAuthor::TYPES_ROLES,
      'currency' => Event::CURRENCY_TYPES,
      'sold' => Event::SOLD_TYPES,
      'material' => EntryMaterial::MATERIAL_TYPES,
      'alt_size' => Entry::ALT_SIZE_TYPES,
    }
    render json: data
  end

  # we don't ever destroy anything, we just mark it as deleted
  def destroy
    @entry.deleted = true
    @entry.updated_by_id = current_user.id
    @entry.save!

    Sunspot.remove(@entry)

    # if we call respond_with(@entry), which is more rails-ish, the
    # response is a 302 to a #show, but jquery's ajax code gets stuck
    # in an redirect loop, deleting the object over and over again. So
    # we force-return a 200 with an empty body for JSON calls to this
    # action.
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
    end
  end

  def similar
    @similar_ids = @entry.similar
    respond_to do |format|
      format.json
    end
  end

  def mark_as_approved
    ids = params[:ids]
    if ids.present?
      ids = ids.map(&:to_i)
      Entry.where('id IN (?)', ids).update_all(
        approved: true,
        approved_by_id: current_user.id,
        approved_at: DateTime.now,
      )
      # do this immediately, rather than use delayed_job, so that
      # admin UI reloads with accurate data
      Sunspot.index Entry.where('id IN (?)', ids)
    end
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
    end
  end

  private

  def set_entry
    @entry = Entry.find(params[:id])
  end

  def entry_params_for_create_and_edit
    # Note that we don't call require(:entry), which is the typical
    # Rails convention, because Rails' wrapped parameters feature
    # doesn't pick up the *_attributes fields that way.
    params.permit(
      :catalog_or_lot_number,
      :institution_id,
      :transaction_type,
      :folios, :num_lines, :num_columns,
      :height, :width, :alt_size,
      :miniatures_fullpage, :miniatures_large, :miniatures_small, :miniatures_unspec_size,
      :initials_historiated, :initials_decorated,
      :manuscript_binding, :manuscript_link, :other_info,
      :entry_titles_attributes => [ :id, :title, :common_title, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_authors_attributes => [ :id, :observed_name, :author_id, :role, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_dates_attributes => [ :id, :observed_date, :date_normalized_start, :date_normalized_end, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_artists_attributes => [ :id, :observed_name, :artist_id, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_scribes_attributes => [ :id, :observed_name, :scribe_id, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_languages_attributes => [ :id, :language_id, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_materials_attributes => [ :id, :material, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_places_attributes => [ :id, :place_id, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_uses_attributes => [ :id, :use, :_destroy ],
      :events_attributes  => [
        :id, :primary, :start_date, :start_date_normalized_start, :start_date_normalized_end, :end_date, :end_date_normalized_start, :end_date_normalized_end, :comment, :sold, :price, :currency, :other_currency, :_destroy,
        {
          :event_agents_attributes => [:id, :observed_name, :agent_id, :role, :uncertain_in_source, :supplied_by_data_entry, :_destroy]
        }
      ]
    )
  end

end
