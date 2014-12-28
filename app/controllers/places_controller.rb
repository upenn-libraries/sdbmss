class PlacesController < ApplicationController
  include ResourceSearch

  before_action :set_place, only: [:show, :show_json, :edit, :update, :destroy]

  def create
    @place = Place.new(params.permit(:name))
    @place.save!
  end

  private

  def set_place
    @place = Place.find(params[:id])
  end

end
