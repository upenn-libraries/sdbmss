# fix me: change to strict catalog management system for records; remove GAME functionality
class DericciRecordsController < ApplicationController

  def index
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

  def show
    @record = DericciRecord.find(params[:id]) 
  end

end