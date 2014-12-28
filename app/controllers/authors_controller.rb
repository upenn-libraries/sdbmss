class AuthorsController < ApplicationController
  before_action :set_author, only: [:show, :show_json, :edit, :update, :destroy]

  include ResourceSearch

  def create
    @author = Author.new(params.permit(:name))
    @author.save!
  end

  private

  def set_author
    @author = Author.find(params[:id])
  end

end
