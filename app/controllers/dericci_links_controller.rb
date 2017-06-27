class DericciLinksController < ApplicationController

  load_and_authorize_resource :only => [:create, :destroy]

  def create
    d = DericciLink.new(dericci_link_params)
    d.update(created_by: current_user)
    d.save!
    flash[:success] = "You have successfully added your confirmation to this De Ricci record link!"
    if params[:from_name]
      redirect_to name_path(d.name)
    else
      redirect_to dericci_record_path(d.dericci_record)
    end
  end

  def delete_many    
    links = DericciLink.where(id: params[:ids])
    if links.count > 0
      name = links.first.name.id
      record = links.first.dericci_record.id
      flash[:success] = "The link has been removed!"
    end
    links.destroy_all
    if params[:from_name]
      redirect_to name_path(name)
    else
      redirect_to dericci_record_path(record)
    end  
  end

  private

  def dericci_link_params
    params.permit(:name_id, :dericci_record_id)
  end

end