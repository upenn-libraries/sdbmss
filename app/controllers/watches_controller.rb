class WatchesController < ApplicationController

  def create
    w = Watch.create!(watches_params)
    redirect_to polymorphic_path(w.watched)
  end

  def destroy
    w = Watch.find(params[:id])
    w.destroy!
    redirect_to polymorphic_path(w.watched)
  end

  def index
    @watches = current_user.watches
  end

  private

  def watches_params
    params.permit(:id, :watched_id, :watched_type, :user_id)
  end
end