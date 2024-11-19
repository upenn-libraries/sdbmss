class DownloadsController < ApplicationController

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  def index
    @downloads = Download.where({user_id: current_user.id})
  end

#  def create
#    super
#  end

  def destroy
    @download = Download.find(params[:id])
    @download.destroy
    redirect_to downloads_path
  end

  def show
    @download = Download.find(params[:id])
    if @download.user  != current_user
      flash[:error] = "You cannot access another user's downloads."
      redirect_to root_path
    elsif @download.status == 0
      render text: "in progress"
      #flash[:error] = "Download is still in progress."
      #redirect_to downloads_path
    elsif @download.status >= 1 && !params[:ping]
      send_file "tmp/" + @download.get_path, :filename => @download.filename, :type=>"csv", :x_sendfile=>true
      # download is 'deleting'
      @download.update({status: 2})
      # adjust timing of this as appropriate
      @download.delay(run_at: 1.minutes.from_now).destroy
    else
      render text: "done"
    end
  end
end