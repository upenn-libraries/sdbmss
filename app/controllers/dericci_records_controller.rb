class DericciRecordsController < ApplicationController

  before_action :set_model, only: [:show, :edit, :update, :destroy]

  def index
    @count = params[:limit] ? params[:limit].to_i : 20
    @page = params[:page] ? params[:page].to_i : 0
    letter = params[:letter] || ""
    @offset = @page * @count
    term = params[:term] || ""
    field = params[:field] || "name"
    @total = DericciRecord.where("#{field} LIKE '%#{term}%'").where("name LIKE '#{letter}%'").count
    @num_pages = (@total / @count).to_i
    @pages = [*[@page-2,0].max..[@page+2,@num_pages].min] 
    @records = DericciRecord.where("#{field} LIKE '%#{term}%'").where("name LIKE '#{letter}%'").limit(@count).offset(@offset)
  end

  def show
  end

  def edit
  end

  def update
    @record.update(dericci_record_params)
    redirect_to dericci_record_path(@record)
  end

  private

  def set_model
    @record = DericciRecord.find(params[:id])
  end

  def dericci_record_params
    params.require(:dericci_record).permit(:name, :url, :size, :cards, :senate_house, :other_info, :place, :dates, :flagged)
  end

end