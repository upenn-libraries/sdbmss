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
    # once names are linked to these, we WILL need 
    puts "should be deprecated"
    @record = DericciRecord.find(params[:id]) 
    render partial: "show", locals: {record: @record}
  end

  def update
  # fix me: does it even make sense to use nested attributes, etc. when I'm not even using them the right way
    params[:records].each do |p|
      d = DericciRecord.find(p[:id])
      if p[:dericci_links_attributes]
        p[:dericci_links_attributes].each do |l|
          link = d.dericci_links.new(name_id: l[:name_id], dericci_record: d)
          link.save_by(current_user)
        end
      end
    end
    respond_to do |format|
      format.json { render json: {message: "Success!"} }
    end
  end
end