class EntriesController < ApplicationController
  before_action :set_entry, only: [:show, :show_json, :edit, :update, :destroy]

  before_action :set_entry, only: [:show, :show_json, :edit, :update, :destroy]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

  respond_to :html, :json

  def show
  end

  # JSON data structure optimized for editing page
  def show_json
    respond_to do |format|
      format.json { render "show.json.rabl" }
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
    @entry = Entry.new
    @entry.created_by_id = current_user.id
    update
  end

  def edit
  end

  def update
    begin
      ActiveRecord::Base.transaction do
        @entry.update!(
          params.permit(
          :catalog_or_lot_number,
          :folios, :num_lines, :num_columns,
          :height, :width, :alt_size,
          :miniatures_fullpage, :miniatures_large, :miniatures_small, :miniatures_unspec_size,
          :initials_historiated, :initials_decorated,
          :manuscript_binding, :manuscript_link, :other_info,
        ))

        Reconciler.reconcile_assoc @entry, params["entry_titles"], EntryTitle, 'entry_id', [:title, :common_title]
        Reconciler.reconcile_assoc @entry, params["entry_authors"], EntryAuthor, 'entry_id', [:author_id, :observed_name]
        Reconciler.reconcile_assoc @entry, params["entry_dates"], EntryDate, 'entry_id', [:date, :circa]
        Reconciler.reconcile_assoc @entry, params["entry_artists"], EntryArtist, 'entry_id', [:artist_id]
        Reconciler.reconcile_assoc @entry, params["entry_scribes"], EntryScribe, 'entry_id', [:scribe_id]
        Reconciler.reconcile_assoc @entry, params["entry_languages"], EntryLanguage, 'entry_id', [:language_id]
        Reconciler.reconcile_assoc @entry, params["entry_materials"], EntryMaterial, 'entry_id', [:material]
        Reconciler.reconcile_assoc @entry, params["entry_places"], EntryPlace, 'entry_id', [:place_id]
        Reconciler.reconcile_assoc @entry, params["entry_uses"], EntryUse, 'entry_id', [:use]
        Reconciler.reconcile_assoc @entry, params["events"], Event, 'entry_id', [:primary, :acquire_date, :end_date, :comment, :sold, :price, :currency, :other_currency] do |event, model_params|
          Reconciler.reconcile_assoc event, model_params['event_agents'], EventAgent, 'event_id', [:observed_name, :agent_id, :role]
        end

        if params[:new_comment].present?
          ec = EntryComment.new(
            entry_id: @entry.id,
            comment: params[:new_comment],
            created_by: current_user)
          ec.save!
        end

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

end
