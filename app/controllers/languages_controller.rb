class LanguagesController < ApplicationController
  include ResourceSearch

  before_action :set_language, only: [:show, :show_json, :edit, :update, :destroy]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

  respond_to :html, :json

  def index
  end

  def new
    @language = Language.new
  end

  def create
    @language = Language.new(language_params)
    @language.save!
    respond_with(@language)
  end

  def update
    @language.update(language_params)
    respond_with(@language)
  end

  def search_results_map(results)
    ids = results.map { |h| h[:id] }
    counts = Language.joins(:entry_languages).where(id: ids).group("languages.id").count("entry_languages.id")
    results.map { |h| h[:count] = counts[h[:id]] || 0; h }
  end

  private

  def set_language
    @language = Language.find(params[:id])
  end

  def language_params
    params.require(:language).permit(:name)
  end

end
