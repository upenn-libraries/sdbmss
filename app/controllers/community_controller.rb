
class CommunityController < ApplicationController

  def stats
    respond_to do |format|
      format.json {
        i = 0
        params = stats_params
        quantity = params[:quantity].to_i || 0;
        if params[:measure] == "month"
          date = quantity.month
        elsif params[:measure] == "week"
          date = quantity.week
        else
          date = quantity.day
        end
        activity = Activity.includes(:user).where(event: "update").where("created_at > ?", Date.today - date).group_by { |e| e.user }.map{ |key, value| [key.username, value.count, key.role]}
        entries = Entry.where("created_at > ?", Date.today - date).group_by { |e| e.created_by }.map{ |key, value| [key.username, (i += 1), Set.new(value.map(&:created_at)).count, key.role, value.count] }
        render json: {result: "you did it!", entries: entries, activity: activity }
      }
    end
  end

  private

  def stats_params
    params.permit(:quantity, :measure)
  end

end
