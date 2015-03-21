class EntriesController < ApplicationController

  before_action :set_entry, only: [:show, :show_json, :edit, :update, :destroy, :find_or_create_manuscript, :similar]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :find_or_create_manuscript, :similar]

  respond_to :html, :json

  # JSON data structure optimized for editing page. This weird action
  # exists because we want CatalogController to handle #show, but we
  # want to format the JSON differently from how it does it.
  def show_json
    respond_to do |format|
      format.json { render "show.json" }
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
          comment: params[:new_comment],
          created_by: current_user)
        ec.save!
      end
    end
    render "show"
  end

  def edit
    expires_now
  end

  def update
    begin
      ActiveRecord::Base.transaction do
        filtered = entry_params_for_create_and_edit
        @entry.update!(filtered)

        if params[:new_comment].present?
          ec = EntryComment.new(
            entry_id: @entry.id,
            comment: params[:new_comment],
            created_by: current_user)
          ec.save!
        end

      end

      # Sunspot doesn't auto index here, probably bc it is hooked into
      # after_save events, which aren't fired on #update! calls
      Sunspot.index @entry

    rescue Exception => e
      logger.error(e.to_s + "\n\n" + e.backtrace.join("\n"))
      render :json => { :errors => e.backtrace.to_s }, :status => :unprocessable_entity
      return
    end
    render "show"
  end

  # returns JSON containing type constants
  def types
    data = {
      'author_role' => EntryAuthor::TYPES_ROLES,
      'circa' => EntryDate::CIRCA_TYPES,
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

  def find_or_create_manuscript
    if @entry.get_manuscript
      respond_to do |format|
        format.html { render "manuscript_already_exists" }
      end
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
      :folios, :num_lines, :num_columns,
      :height, :width, :alt_size,
      :miniatures_fullpage, :miniatures_large, :miniatures_small, :miniatures_unspec_size,
      :initials_historiated, :initials_decorated,
      :manuscript_binding, :manuscript_link, :other_info,
      :entry_titles_attributes => [ :title, :common_title, :uncertain_in_source, :supplied_by_data_entry ],
      :entry_authors_attributes => [ :observed_name, :author_id, :role, :uncertain_in_source, :supplied_by_data_entry ],
      :entry_dates_attributes => [ :date, :circa ],
      :entry_artists_attributes => [ :observed_name, :artist_id, :uncertain_in_source, :supplied_by_data_entry ],
      :entry_scribes_attributes => [ :observed_name, :scribe_id, :uncertain_in_source, :supplied_by_data_entry ],
      :entry_languages_attributes => [ :language_id, :uncertain_in_source, :supplied_by_data_entry ],
      :entry_materials_attributes => [ :material, :uncertain_in_source, :supplied_by_data_entry ],
      :entry_places_attributes => [ :place_id, :uncertain_in_source, :supplied_by_data_entry ],
      :entry_uses_attributes => [ :use ],
      :events_attributes  => [
        :primary, :start_date, :end_date, :comment, :sold, :price, :currency, :other_currency,
        {
          :event_agents_attributes => [:observed_name, :agent_id, :role, :uncertain_in_source, :supplied_by_data_entry]
        }
      ]
    )
  end

end
