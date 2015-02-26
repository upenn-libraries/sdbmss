class ArtistsController < ApplicationController
  include ResourceSearch

  before_action :set_artist, only: [:show, :show_json, :edit, :update, :destroy]

  def create
    @artist = Artist.new(artist_params)
    @artist.save!
  end

  private

  def set_artist
    @artist = Artist.find(params[:id])
  end

  def artist_params
    params.require(:artist).permit(:name)
  end

end
