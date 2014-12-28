class ArtistsController < ApplicationController
  include ResourceSearch

  before_action :set_artist, only: [:show, :show_json, :edit, :update, :destroy]

  def create
    @artist = Artist.new(params.permit(:name))
    @artist.save!
  end

  private

  def set_artist
    @artist = Artist.find(params[:id])
  end

end
