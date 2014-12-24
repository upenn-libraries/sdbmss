class EntriesController < ApplicationController
  before_action :set_entry, only: [:show, :show_json, :edit, :update, :destroy]

  respond_to :html, :json

  def show
  end

  # JSON data structure optimized for editing page
  def show_json
    respond_to do |format|
      format.json { render "show.json.rabl" }
    end
  end

  def edit
  end

  def update
    entry_params = params.permit(
      :catalog_or_lot_number,
      :folios, :num_lines, :num_columns,
      :height, :width, :alt_size,
      :miniatures_fullpage, :miniatures_large, :miniatures_small, :miniatures_unspec_size,
      :initials_historiated, :initials_decorated,
      :manuscript_binding, :manuscript_link, :other_info,
    )
    begin
      ActiveRecord::Base.transaction do
        @entry.update!(entry_params)

        reconcile_assoc @entry, "entry_titles", EntryTitle, 'entry_id', [:title, :common_title]
        reconcile_assoc @entry, "entry_authors", EntryAuthor, 'entry_id', [:author_id, :observed_name]
        reconcile_assoc @entry, "entry_dates", EntryDate, 'entry_id', [:date, :circa]
        reconcile_assoc @entry, "entry_artists", EntryArtist, 'entry_id', [:artist_id]
        reconcile_assoc @entry, "entry_scribes", EntryScribe, 'entry_id', [:scribe_id]
        reconcile_assoc @entry, "entry_languages", EntryLanguage, 'entry_id', [:language_id]
        reconcile_assoc @entry, "entry_materials", EntryMaterial, 'entry_id', [:material]
        reconcile_assoc @entry, "entry_places", EntryPlace, 'entry_id', [:place_id]
        reconcile_assoc @entry, "entry_uses", EntryUse, 'entry_id', [:use]

      end
    rescue Exception => e
      puts e.backtrace.join("\n")
      render :json => { :errors => e.backtrace.to_s }, :status => 500
      return
    end
    respond_with(@entry)
  end

  # returns JSON containing values for dropdowns on add/edit entry
  # page
  def entry_form_dropdown_values
    data = {
        'circa' => EntryDate::CIRCA_TYPES,
        'currency' => Event::CURRENCY_TYPES,
        'sold' => Event::SOLD_TYPES,
        'material' => EntryMaterial::MATERIAL_TYPES,
        'alt_size' => Entry::ALT_SIZE_TYPES,
    }
    render json: data
  end

  private

  def set_entry
    @entry = Entry.find(params[:id])
  end

  # Reconciles 1-M (parent-children) records, based on incoming params
  #
  # parent = single object containing the many
  # param_name = name of param containing array of records
  # child_model_name = constant for the activerecord model for child records
  # fk_name = name of FK field on child record
  # attributes = array of symbols to use for updating model from params
  def reconcile_assoc parent, param_name, child_model_name, fk_name, attributes
    ids_persisted = []
    params_for_name = params[param_name]
    params_for_name = [] if params_for_name.blank?
    params_for_name.each do |model_params|
      model_obj = model_params['id'].present? ? child_model_name.find(model_params['id']) : child_model_name.new(fk_name => parent.id)
      model_obj.assign_attributes(model_params.permit(*attributes))
      model_obj.save!
      ids_persisted << model_obj.id
    end
    child_model_name.where(fk_name => parent).where("id not in (?)", ids_persisted).destroy_all
  end

end
