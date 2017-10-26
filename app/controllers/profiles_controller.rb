
class ProfilesController < ApplicationController

  def show
    if !current_user
      flash[:error] = "You must be logged in to view someone's profile page."
      redirect_to root_path
      return
    end

    @user = User.find_by(username: params[:username])
    respond_to do |format|
      format.html do
        @display = {
          id: @user.id,
          username: @user.username,
          fullname: @user.fullname || "Not set",
          email: @user.email_is_public ? @user.email : "This user's email is not publicly available.",
          last_seen: @user.updated_at ? @user.updated_at.to_formatted_s(:long) : "",
          role: @user.role,
          biography: @user.bio.present? ? @user.bio : "This user has chosen not to share any biographical details.",
          institution: @user.institutional_affiliation  || "Unaffiliated",
          sources_created: @user.sources.count,
          entries_created: @user.entries.where(deprecated: false).count
        }
        @online = @user.updated_at && @user.updated_at > 10.minutes.ago
        start_date = Activity.where(user: current_user).order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)").last
        @activities = Activity.where(user: @user).where("created_at > ?", start_date).order("created_at desc").group_by { |a| a.created_at.to_date }
      end
      format.json do
        n = Name.select(:id, :created_at).where(created_by: @user).order("created_at asc")
        em = EntryManuscript.select(:id, :created_at).where(created_by: @user)
        p = Entry.joins(:source).select(:id, :created_at).where({created_by: @user, :sources => {:source_type_id => 4}})

        render json: {
            Names: (n.to_a + Rating.select(:id, :created_at, :qualifier).where(ratable_type: Name, ratable_id: n.map(&:id)).order("created_at asc").to_a).sort { |a, b| a.created_at <=> b.created_at },
            Links: (em.to_a + Rating.select(:id, :created_at, :qualifier).where(ratable_type: EntryManuscript, ratable_id: em.map(&:id)).order("created_at asc").to_a).sort { |a, b| a.created_at <=> b.created_at },
            Observations: (p.to_a + Rating.select(:id, :created_at, :qualifier).where(ratable_type: Entry, ratable_id: p.map(&:id)).order("created_at asc").to_a).sort { |a, b| a.created_at <=> b.created_at }
        }
      end   
    end
  end

end
