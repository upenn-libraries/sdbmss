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

    # this is quite the query! -> and quite slow! but it should limit things correctly
    #@records = DericciRecord.where("(id IN (SELECT dericci_record_id from (SELECT * FROM dericci_links GROUP BY dericci_record_id, name_id HAVING sum(reliability) < 4) A where A.created_by_id <> #{current_user.id})) OR ((id NOT IN (SELECT dericci_record_id FROM dericci_links WHERE true)))").limit(20).order("RAND()")
    @records = DericciRecord.where(out_of_scope: false).where.not("id in (?)", [0] + DericciLink.where(created_by: current_user).map(&:dericci_record_id) + DericciRecordFlag.where(created_by: current_user).map(&:dericci_record_id)).where({verified_id: nil}).order("cards desc").limit(15)
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
      format.json { render json: DericciLink.select(:created_at, :name_id, :dericci_record_id).order(:created_at) }
    end
  end

  private

  def game_params
    p = params.require(:dericci_game).permit(
      :skipped, :completed, :flagged, :dericci_records_attributes => [:id, 
        dericci_links_attributes: [:id, :name_id, :other_info, :_destroy], 
        comments_attributes: [:commentable_id, :commentable_type, :comment],
        dericci_record_flags_attributes: [:id, :reason]
      ])
    # this incredibly inelegant solution is here because for some reason deep_merge would not do what it was supposed to...
    p[:dericci_records_attributes].each do |dra|
      dra[:dericci_links_attributes].each do |dla|
        dla[:created_by_id] = current_user.id
      end
      if dra[:comments_attributes]
        dra[:comments_attributes].each do |ca|
          ca[:created_by_id] = current_user.id
        end
      end
      if dra[:dericci_record_flags_attributes]
        dra[:dericci_record_flags_attributes].each do |drfa|
          drfa[:created_by_id] = current_user.id
        end
      end
    end
    p
  end

end