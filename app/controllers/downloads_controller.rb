class DownloadsController < ApplicationController

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  def index
    @downloads = Download.where({user_id: current_user.id})
  end

  def create
    super
#   fix me: auto-delete file after certain time limit (1 hour? 1 week?)
    #@download = Download.find(params[:id])
  end

  def destroy
    @download = Download.find(params[:id])
    @download.destroy
    redirect_to downloads_path
  end

  def show
    @download = Download.find(params[:id])
    if @download.status == 0
      render text: "in progress"
    elsif @download.status >= 1 && !params[:ping]
      send_file "downloads/" + @download.id.to_s + "_" + @download.user.username + "_" + @download.filename, :filename => @download.filename, :type=>"csv", :x_sendfile=>true
      # download is 'deleting'
      @download.update({status: 2})
      # adjust timing of this as appropriate
      @download.delay(run_at: 5.minutes.from_now).destroy
    else
      render text: "done"
    end
  end
end