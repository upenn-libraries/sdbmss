class GroupsController < ApplicationController

  before_action :authenticate_user!

  def index
    @groups = Group.where(created_by: current_user)
  end

  def create
    @group = Group.new(group_params)
    @group.save_by(current_user)
    GroupUser.create!({group: @group, user: current_user})
    redirect_to groups_path
  end

  private

  def group_params
    params.require(:group).permit(:name, :public)
  end

end