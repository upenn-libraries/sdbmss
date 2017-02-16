class  DericciGamesController < ApplicationController
  
  load_and_authorize_resource :only => [:index, :show, :new, :update]

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
    game = DericciGame.find(params[:id])
    game.update!(game_params)
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

  def game_params
    p = params.require(:dericci_game).permit(
      :dericci_records_attributes => [:id, :dericci_links_attributes => [:id, :name_id, :other_info, :_destroy]])
    # this incredibly inelegant solution is here because for some reason deep_merge would not do what it was supposed to...
    p[:dericci_records_attributes].each do |dra|
      dra[:dericci_links_attributes].each do |dla|
        dla[:created_by_id] = current_user.id
        dla[:reliability] = user_reliability(current_user)
      end
    end
    p
  end

end