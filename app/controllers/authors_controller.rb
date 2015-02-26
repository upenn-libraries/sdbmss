class AuthorsController < ApplicationController
  include ResourceSearch

  before_action :set_author, only: [:show, :show_json, :edit, :update, :destroy]

  def create
    @author = Author.new(author_params)
    @author.save!
  end

  private

  def set_author
    @author = Author.find(params[:id])
  end

  def author_params
    params.require(:author).permit(:name)
  end

end
