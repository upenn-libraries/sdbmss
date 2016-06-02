class DownloadsController < ApplicationController

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  def index
    @downloads = Download.where({user_id: current_user.id})
  end

  def show
    @download = Download.find(params[:id])
    send_file "downloads/" + @download.id.to_s + "_" + @download.user.username + "_" + @download.filename, :filename => @download.filename, :type=>"csv", :x_sendfile=>true
  end
end