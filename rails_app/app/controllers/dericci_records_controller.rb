class DericciRecordsController < ApplicationController

  before_action :set_model, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource :only => [:edit, :update]

  def index
    #flash.now[:alert] = "<span class='lead'>Warning!</span> The server hosting the De Ricci Digitized Archive is not available.  Our records and workspace will not function correctly.".html_safe
    @count = params[:limit] ? params[:limit].to_i : 20
    @page = params[:page] ? params[:page].to_i : 0
    letter = params[:letter] || ""
    @offset = @page * @count
    term = params[:term] || ""
    field = params[:field] || "name"
    type = params[:type] || ''
    @records = DericciRecord.where("#{field} LIKE '%#{term}%'").where("name LIKE '#{letter}%'").where("senate_house like ?", "%#{type}%")
    if params[:verified_id]
      @records = @records.includes(:dericci_links).where(:dericci_links => {:approved => [nil, false]})
    end
    if params[:flagged]
      @records = @records.joins(:dericci_record_flags)
    end
    if params[:linked]
      @records = @records.joins(:dericci_links)
    end
    if params[:in_scope]
      @records = @records.where(out_of_scope: false)
    end
    @total = @records.count
    @num_pages = (@total / @count).to_i
    @pages = [*[@page-2,0].max..[@page+2,@num_pages].min] 
    @records = @records.limit(@count).offset(@offset)
  end

  def show
    #flash.now[:alert] = "<span class='lead'>Warning!</span> The server hosting the De Ricci Digitized Archive is not available.  Our records and workspace will not function correctly.".html_safe
    respond_to do |format|
      format.html {}
      format.json { render json: @record }
    end
  end

  def edit
  end

  def new
    @record = DericciRecord.new
    render "edit"
  end

  def create
    @record = DericciRecord.create!(dericci_record_params)
    redirect_to dericci_record_path(@record)
  end

  def update
    @record.update_by(current_user, dericci_record_params)
    #@record.dericci_links.where(name_id: @record.verified_id).map(&:created_by).each do |created_by|
    #  if created_by != current_user
    #    created_by.notify("#{current_user} has verified a link you made between a De Ricci Card and an SDBM Name - thanks for your help!", @record, "update")
    #  end
    #end
    respond_to do |format|
      format.html {
        redirect_to dericci_record_path(@record)        
      }
      format.json { render json: {success: true}}
    end
  end

  private

  def set_model
    @record = DericciRecord.find(params[:id])
  end

  def dericci_record_params
    params.require(:dericci_record).permit(:name, :url, :size, :cards, :senate_house, :other_info, :place, :dates, :verified_id, :out_of_scope, :dericci_record_flags_attributes => [:id, :reason, :_destroy], :dericci_links_attributes => [:name_id, :dericci_record_id, :approved, :created_by_id])
  end

end