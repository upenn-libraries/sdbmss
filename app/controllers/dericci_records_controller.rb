class DericciRecordsController < ApplicationController

  before_action :set_model, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource :only => [:edit, :update]

  def index
    @count = params[:limit] ? params[:limit].to_i : 20
    @page = params[:page] ? params[:page].to_i : 0
    letter = params[:letter] || ""
    @offset = @page * @count
    term = params[:term] || ""
    field = params[:field] || "name"
    type = params[:type] || ''
    @total = DericciRecord.where("#{field} LIKE '%#{term}%'").where("name LIKE '#{letter}%'").where("senate_house like ?", "%#{type}%")
    @records = DericciRecord.where("#{field} LIKE '%#{term}%'").where("name LIKE '#{letter}%'").where("senate_house like ?", "%#{type}%")
    if params[:verified_id]
      @total = @total.where(verified_id: nil)
      @records = @records.where(verified_id: nil)
    end
    if params[:flagged]
      @total = @total.joins(:dericci_record_flags)
      @records = @records.joins(:dericci_record_flags)
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
    params.require(:dericci_record).permit(:name, :url, :size, :cards, :senate_house, :other_info, :place, :dates, :verified_id, :out_of_scope, :dericci_record_flags_attributes => [:id, :reason, :_destroy])
  end

end