class PrivateMessagesController < ApplicationController
  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  def index
    if !current_user
      flash[:warning] = "You must be logged in to view your private messages."
      redirect_to dashboard_path
    else
      if params[:sent_by]
        @sent_by = true
        @messages = current_user.private_messages.sent
      else
        @messages = current_user.private_messages.received
      end
    end
  end

  def new
    if params[:user_id] && User.exists?(params[:user_id])
      @message = PrivateMessage.new

      @user = User.find(params[:user_id])
        if params[:private_message_id]
        @reply = PrivateMessage.find(params[:private_message_id])
        @messages = reply_chain(@reply)
      end
    else
    end
  end
  
  def create
    to_user = params[:to_user]
    @message = PrivateMessage.create(params_for_create_message)
    @message.user_messages.create({user_id: current_user.id, method: "From"})
    @message.user_messages.create!({user_id: to_user.to_i, method: "To"})

    redirect_to @message
  end

  def show
    if params[:id] && PrivateMessage.exists?(params[:id])
      @message = PrivateMessage.find(params[:id])
    end
  end

  def destroy
    # how should this be handled?!
  end

  private

  def params_for_create_message
    params.require(:private_message).permit(:message, :title)
  end

end