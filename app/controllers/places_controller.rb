class PlacesController < ApplicationController
  include ResourceSearch

  before_action :set_place, only: [:show, :show_json, :edit, :update, :destroy]

  def create
    @place = Place.new(place_params)
    @place.save!
  end

  private

  def set_place
    @place = Place.find(params[:id])
  end

  def place_params
    params.require(:place).permit(:name)
  end

end
