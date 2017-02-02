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

  def game
    @records =  DericciRecord.includes(:dericci_links).where(:dericci_links => {id: nil}).limit(20).order("RAND()")
    respond_to do |format|
      format.html {}
      format.json { render json: @records, :include => { :dericci_links => { :only => :name_id }} }
    end
  end

  def show
    puts "should be deprecated"
    @record = DericciRecord.find(params[:id]) 
    render partial: "show", locals: {record: @record}
  end

  def link
    # fix me: use params
    record = DericciRecord.find(params[:id])
    name = Name.find(params[:name_id])
    DericciLink.create(dericci_record: record, name: name);
    render json: record, :include => { :dericci_links => { :only => :name_id }}
  end

  private

  def dericci_params
    params.permit(:term, :field, :page, :limit)
  end
end