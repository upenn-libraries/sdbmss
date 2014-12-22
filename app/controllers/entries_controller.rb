class EntriesController < ApplicationController
  before_action :set_entry, only: [:show, :edit, :update, :destroy]

  def show
    respond_to do |format|
      format.html
      # TODO: unfinished
      format.json {
        render :json => @entry,
               :include => [
                 :entry_titles,
                 :entry_dates,
                 :entry_artists,
                 :entry_scribes,
                 :entry_languages,
                 :entry_materials,
                 :entry_places,
                 :entry_uses,
                 :events,
                 :entry_authors => { :include => [ :author ] },
               ]
      }
    end
  end

  def edit
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
