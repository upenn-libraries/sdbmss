class  DericciGamesController < ApplicationController
  
  include LogActivity

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

    # this is quite the query!
    @records = DericciRecord.where("(id IN (SELECT dericci_record_id from (SELECT * FROM dericci_links GROUP BY dericci_record_id HAVING sum(reliability) < 4) A where A.created_by_id <> #{current_user.id})) OR ((id NOT IN (SELECT dericci_record_id FROM dericci_links WHERE true)))").limit(20).order("RAND()")
    puts @records.count
    @game.dericci_game_records.create!(@records.map{ |r| {dericci_record: r}})
    redirect_to dericci_game_path(@game)
  end

  def update
    ActiveRecord::Base.transaction do    
      game = DericciGame.find(params[:id])
      game.update!(game_params)
      @transaction_id = PaperTrail.transaction_id
    end
    flash[:success] = "Thank you for playing the Dericci Archives Game!"
    respond_to do |format|
      format.json { render json: {message: "Success!"} }
    end
  end

  def stats
    respond_to do |format|
      format.json { render json: DericciLink.select(:created_at, :reliability, :name_id, :dericci_record_id).order(:created_at) }
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
      :skipped, :completed, :dericci_records_attributes => [:id, :dericci_links_attributes => [:id, :name_id, :other_info, :_destroy]])
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