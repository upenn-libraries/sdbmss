class ScribesController < ApplicationController
  before_action :set_scribe, only: [:show, :show_json, :edit, :update, :destroy]

  include ResourceSearch

  def create
    @scribe = Scribe.new(params.permit(:name))
    @scribe.save!
  end

  private

  def set_scribe
    @scribe = Scribe.find(params[:id])
  end

end
