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
    @groups_created_by_me = Group.where(created_by: current_user)
    @groups_including_me = current_user.groups
  end

  def new
    @model = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.save_by(current_user)
    GroupUser.create!({group: @group, user: current_user})
    redirect_to groups_path
  end

  def destroy
    @model = Group.find(params[:id])
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
    params.require(:group).permit(:name, :public, :description)
  end

end