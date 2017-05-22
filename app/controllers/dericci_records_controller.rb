class DericciRecordsController < ApplicationController

  before_action :set_model, only: [:show, :edit, :update, :destroy]

  def index
    @count = params[:limit] ? params[:limit].to_i : 20
    @page = params[:page] ? params[:page].to_i : 0
    letter = params[:letter] || ""
    @offset = @page * @count
    term = params[:term] || ""
    field = params[:field] || "name"
    @total = DericciRecord.where("#{field} LIKE '%#{term}%'").where("name LIKE '#{letter}%'")
    @records = DericciRecord.where("#{field} LIKE '%#{term}%'").where("name LIKE '#{letter}%'")
    if params[:verified_id]
      @total = @total.where(verified_id: nil)
      @records = @records.where(verified_id: nil)
    end
    if params[:flagged]
      @total = @total.where(flagged: true)
      @records = @records.where(flagged: true)
    end
    @total = @total.count
    @num_pages = (@total / @count).to_i
    @pages = [*[@page-2,0].max..[@page+2,@num_pages].min] 
    @records = @records.limit(@count).offset(@offset)
  end

  def show
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

  def update
    @record.update_by(current_user, dericci_record_params)
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
    params.require(:dericci_record).permit(:name, :url, :size, :cards, :senate_house, :other_info, :place, :dates, :flagged, :verified_id)
  end

end