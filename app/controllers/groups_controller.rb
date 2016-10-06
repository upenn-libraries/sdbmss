class GroupsController < ApplicationController

  before_action :authenticate_user!
  load_and_authorize_resource :only => [:edit, :update, :destroy]

  def show
    @model = Group.find(params[:id])
  end

  def edit
    @model = Group.find(params[:id])
  end

  def update
    @model = Group.find(params[:id])
    @model.update(group_params)
    @model.entries.index
    redirect_to edit_group_path(@model)
  end

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
    params.require(:group).permit(:name, :public, :description)
  end

end