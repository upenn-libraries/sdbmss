class PrivateMessagesController < ApplicationController
  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  def index
    if !current_user
      flash[:warning] = "You must be logged in to view your private messages."
      redirect_to dashboard_path
    else
      if params[:sent_by]
        @sent_by = true
        @messages = PrivateMessage.where({created_by: current_user})
      else
        @messages = current_user.private_messages
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

      flash[:notice] = "Please select a user to send a message to."
      #redirect_to dashboard_path
    end
  end
  
  def create
    @message = PrivateMessage.new(params_for_create_message)
    @message.save_by(current_user)
    flash[:notice] = "Message created!"
    redirect_to private_message_path(@message)
  end

  def show
    if params[:id] && PrivateMessage.exists?(params[:id])
      @message = PrivateMessage.find(params[:id])
      @messages = reply_chain(@message)
      @children = @message.children
    end
  end

  def destroy
    # how should this be handled?!
  end

  private

  def reply_chain(message)
    messages = []
    m_id = message.private_message_id
    while !m_id.nil? do
      m = PrivateMessage.find(m_id)
      messages.unshift(m)
      m_id = m.private_message_id
    end
    #messages.push(message)
    messages
  end

  def params_for_create_message
    params.permit(:message, :user_id, :private_message_id)
  end

end