class EntriesController < ApplicationController
  before_action :set_entry, only: [:show, :edit, :update, :destroy]

  respond_to :html, :json

  def show
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
      end
    rescue Exception => e
      render :json => { :errors => e.to_s }, :status => 500
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
