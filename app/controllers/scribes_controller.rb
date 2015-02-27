class ScribesController < ApplicationController
  include ResourceSearch

  before_action :set_scribe, only: [:show, :show_json, :edit, :update, :destroy]

  def create
    @scribe = Scribe.new(scribe_params)
    @scribe.save!
  end

  private

  def set_scribe
    @scribe = Scribe.find(params[:id])
  end

  def scribe_params
    params.require(:scribe).permit(:name)
  end

end
