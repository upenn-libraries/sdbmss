class GroupsController < ApplicationController

  before_action :authenticate_user!
  load_and_authorize_resource :only => [:edit, :update, :destroy]

  before_action :set_model, only: [:show, :edit, :update, :destroy]

  def set_model
    @model = Group.find(params[:id])
  end

  def update
    @model.update(group_params)
    @model.entries.index
    redirect_to edit_group_path(@model)
  end

  def index
    get_groups
  end

  def show_all
    get_groups
    render :index, :layout => false
  end

  def new
    @model = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.save_by(current_user)
    GroupUser.create!({group: @group, user: current_user, role: "Manager", confirmed: true, created_by: current_user})
    redirect_to groups_path
  end

  def destroy
    name = @model.name
    if @model.destroy!
      flash[:success] = "#{name} was deleted successfully."
    else
      flash[:error] = "There was an unknown error deleting this group."
    end
    redirect_to groups_path
  end

  private

  def group_params
    params.require(:group).permit(:name, :public, :description, :group_users_attributes => [:id, :confirmed, :role])
  end

  # is there a better way of doing this?
  def get_groups
    @groups_admin = Group.joins(:group_users).where(:group_users => {:role => "Manager", :user_id => current_user.id, :confirmed => true}).distinct
    @groups_member = Group.joins(:group_users).where(:group_users => {:role => "Member", :user_id => current_user.id, :confirmed => true}).distinct
    @groups_invites = Group.joins(:group_users).where(:group_users => {:role => "Member", :user_id => current_user.id, :confirmed => false}).where.not(:group_users => {created_by: current_user}).distinct
    @groups_requests = Group.joins(:group_users).where(:group_users => {:role => "Member", :user_id => current_user.id, :confirmed => false, :created_by => current_user}).distinct
  end

end