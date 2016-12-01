
class ProfilesController < ApplicationController

  def show
    if !current_user
      flash[:error] = "You must be logged in to view someone's profile page."
      redirect_to root_path
      return
    end

    @user = User.find_by(username: params[:username])
    @display = {
      id: @user.id,
      username: @user.username,
      fullname: @user.fullname || "Not set",
      email: @user.email_is_public ? @user.email : "This user's email is not publicly available.",
      last_seen: @user.updated_at ? @user.updated_at.to_formatted_s(:long) : "",
      role: @user.role,
      biography: @user.bio || "This user has chosen not to share any biographical details.",
      institution: @user.institutional_affiliation  || "Unaffiliated",
      sources_created: @user.sources.count,
      entries_created: @user.entries.where(deprecated: false).count
    }
    @online = @user.updated_at && @user.updated_at > 10.minutes.ago
    start_date = Activity.where(user: current_user).order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)").last
    @activities = Activity.where(user: current_user).where("created_at > ?", start_date).order("created_at desc").group_by { |a| a.created_at.to_date }      
  end

end
