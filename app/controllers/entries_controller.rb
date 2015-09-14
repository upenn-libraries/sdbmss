
# Manage Entries screen is much more complicated than other screens
# that subclass from ManageModelsController, but we use it anyway
# for consistency.
#
# Note: CSV Export from Manage Entries page makes use of Blacklight
# search; see CatalogControllerConfiguration to see how search results
# are rendered in CSV format.
class EntriesController < ManageModelsController

  # include Blacklight modules so that we get the same search
  # functionality as in CatalogController, except that in this
  # controller, we customize a few things about how search works.

  include Blacklight::Catalog

  include CatalogControllerConfiguration

  # the blacklight_advanced_search gem includes this automatically in
  # CatalogController but not here, so we include it explicitly
  include BlacklightAdvancedSearch::Controller

  include CalculateBounds

  include LogActivity

  before_action :set_entry, only: [:show, :show_json, :edit, :update, :destroy, :similar, :history]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :similar, :mark_as_approved]

  respond_to :html, :json

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_approved]

  def model_class
    Entry
  end

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
    success = false
    ActiveRecord::Base.transaction do
      filtered = entry_params_for_create_and_edit
      @entry = Entry.new(filtered)
      @entry.created_by_id = current_user.id
      @entry.source_id = params[:source_id]
      success = @entry.save

      if success
        if params[:new_comment].present?
          c = Comment.new(
            comment: params[:new_comment],
            created_by_id: current_user.id,
            entry_comments_attributes: [
              {
                entry_id: @entry.id,
              }
            ])
          c.save!
        end
        # link to manuscript
        if params[:manuscript_id].present?
          em = EntryManuscript.new(
            entry_id: @entry.id,
            manuscript_id: params[:manuscript_id],
            relation_type: EntryManuscript::TYPE_RELATION_IS
          )
          em.save
        end
      end
    end
    respond_to do |format|
      format.json {
        if success
          render "show"
        else
          json_response = { errors: @entry.errors.messages }
          render json: json_response, status: :unprocessable_entity
        end
      }
    end
  end

  def edit
    expires_now
  end

  def update
    success = false
    errors = nil

    if params[:cumulative_updated_at].to_s == @entry.cumulative_updated_at.to_s
      ActiveRecord::Base.transaction do
        filtered = entry_params_for_create_and_edit
        success = @entry.update_by(current_user, filtered)
        if success
          if params[:new_comment].present?
            c = Comment.new(
              comment: params[:new_comment],
              created_by_id: current_user.id,
              entry_comments_attributes: [
                {
                  entry_id: @entry.id,
                }
              ])
            c.save!
          end
        end
      end
    else
      errors = { base: "Another change was made to the record while you were working. Re-load the page and start over." }
    end

    respond_to do |format|
      format.json {
        if success
          render "show"
        else
          errors_data = errors.present? ? errors : @entry.errors.messages
          json_response = { errors: errors_data }
          render json: json_response, status: :unprocessable_entity
        end
      }
    end
  end

  # returns JSON containing type constants
  def types
    data = {
      'transaction_type' => Entry::TYPES_TRANSACTION,
      'author_role' => EntryAuthor::TYPES_ROLES,
      'currency' => Sale::CURRENCY_TYPES,
      'sold' => Sale::SOLD_TYPES,
      'material' => EntryMaterial::MATERIAL_TYPES,
      'alt_size' => Entry::ALT_SIZE_TYPES,
      'acquisition_method' => Provenance::ACQUISITION_METHOD_TYPES,
    }
    render json: data
  end

  # we don't ever destroy anything, we just mark it as deleted
  def destroy
    @entry.deleted = true
    @entry.updated_by_id = current_user.id
    @entry.save

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

  # this action returns differently formatted JSON results depending
  # on param 'full'
  def similar
    similar = SDBMSS::SimilarEntries.new(@entry)
    if params[:full].present?
      total = similar.count
      max = params[:max].present? ? params[:max].to_i : 10
      entries = similar.first(max).map do |similar_entry|
        similar_entry[:entry]
      end
      respond_to do |format|
        format.json { render :json => { similar: entries.map(&:as_flat_hash), total: total } }
      end
    else
      @similar_ids = Set.new
      similar.each do |similar_entry|
        entry = similar_entry[:entry]
        @similar_ids.add entry.id
      end
      respond_to do |format|
        format.json
      end
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
      :entry_places_attributes => [ :id, :observed_name, :place_id, :uncertain_in_source, :supplied_by_data_entry, :_destroy ],
      :entry_uses_attributes => [ :id, :use, :_destroy ],
      :sales_attributes  => [
        :id, :date, :sold, :price, :currency, :other_currency, :_destroy,
        {
          :sale_agents_attributes => [:id, :observed_name, :agent_id, :role, :uncertain_in_source, :supplied_by_data_entry, :_destroy]
        }
      ],
      :provenance_attributes => [
        :id, :observed_name, :provenance_agent_id, :start_date, :start_date_normalized_start, :start_date_normalized_end, :end_date, :end_date_normalized_start, :end_date_normalized_end, :acquisition_method, :direct_transfer, :comment, :_destroy
      ],
    )
  end

end
