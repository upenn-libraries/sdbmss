class DericciRecordsController < ApplicationController

  def index
    params = dericci_params
    @count = params[:limit] ? params[:limit].to_i : 20
    @page = params[:page] ? params[:page].to_i : 0
    @offset = @page * @count
    term = params[:term] || ""
    field = params[:field] || "name"
    @total = DericciRecord.where("#{field} LIKE '%#{term}%'").count
    @num_pages = (@total / @count).to_i
    @pages = [*[@page-2,0].max..[@page+2,@num_pages].min] 
    @records = DericciRecord.where("#{field} LIKE '%#{term}%'").limit(@count).offset(@offset)
  end

  private

  def dericci_params
    params.permit(:term, :field, :page, :limit)
  end
end