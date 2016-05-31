class DownloadsController < ApplicationController

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  def index
    @downloads = Download.where({user_id: current_user.id})
  end
end