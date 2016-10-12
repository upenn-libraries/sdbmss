class GroupUsersController < ApplicationController

  def update
    group_user = GroupUser.find(params[:id])
    group_user.update(group_user_params)
    redirect_to groups_path
  end

  def destroy
    admin = params[:admin] || false
    group_user = GroupUser.find(params[:id])
    group_user.destroy
    if admin
      redirect_to edit_group_path(group_user.group)
    else
      redirect_to groups_path
    end
  end

  private

  def group_user_params
    params.require(:group_user).permit(:confirmed, :role)
  end

end