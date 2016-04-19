
class ProfilesController < ApplicationController

  def show
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
      entries_created: @user.entries.count
    }
    @online = @user.updated_at && @user.updated_at > 10.minutes.ago
    @activities = Activity.where(user_id: @user.id).limit(10).order(id: :desc)
  end

end
