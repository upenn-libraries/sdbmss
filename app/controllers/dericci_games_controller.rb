class  DericciGamesController < ApplicationController
  
  def index
    @games = DericciGame.where(created_by: current_user)
  end

  def show
    @game = DericciGame.find(params[:id])
    respond_to do |format|
      format.html {}
      format.json {}# render json: @game.dericci_records, :include => { :dericci_links => { :only => [:id, :name_id] }} }
    end
  end

  def new
    @game = DericciGame.create!(created_by: current_user)
    #@records =  DericciRecord.includes(:dericci_links).where('dericci_links.id is NULL or dericci_links.reliability < 4').limit(20).order("RAND()").references(:dericci_links)
    @records =  DericciRecord.includes(:dericci_links).where('dericci_links.id is NULL or dericci_links.reliability < 4').limit(20).references(:dericci_links)
    puts @records.count
    @game.dericci_game_records.create!(@records.map{ |r| {dericci_record: r}})
    redirect_to dericci_game_path(@game)
  end

  def update
  # fix me: make this more rails-y
    params[:records].each do |p|
      d = DericciRecord.find(p[:id])
      if p[:dericci_links]
        p[:dericci_links].each do |l|
          if l[:id]
            link = d.dericci_links.find(l[:id])
            link.update_by(current_user, name_id: l[:name_id])
          elsif (link = d.dericci_links.find_by(name_id: l[:name_id]))
            link.update_by(current_user, reliability: link.reliability + user_reliability(current_user))
          else
            link = d.dericci_links.new(name_id: l[:name_id], dericci_record: d)
            link.save_by(current_user)
          end
        end
      end
    end
    respond_to do |format|
      format.json { render json: {message: "Success!"} }
    end
  end

  private

  def user_reliability(user)
    case user.role
      when "contributor"
        1
      when "editor"
        2
      when "super-editor"
        3
      when "admin"
        4
      else
        0
    end
  end

end