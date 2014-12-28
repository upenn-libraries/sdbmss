class LanguagesController < ApplicationController
  include ResourceSearch

  before_action :set_language, only: [:show, :show_json, :edit, :update, :destroy]

  def create
    @language = Language.new(params.permit(:name))
    @language.save!
  end

  private

  def set_language
    @language = Language.find(params[:id])
  end

end
