class PrivateMessagesController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show, :new, :create, :edit, :update, :destroy, :search]

  before_action :set_model, only: [:show, :destroy]

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_approved, :deprecate]

  def index
    if params[:sent_by]
      @sent_by = true
      @messages = current_user.private_messages.sent.reverse_order
    else
      @messages = current_user.private_messages.received.reverse_order
    end
  end

#  def new
#    if params[:user_id] && User.exists?(params[:user_id].to_i)
#      @message = PrivateMessage.new

#      @user = User.find(params[:user_id])
      #if params[:private_message_id]
      #  @reply = PrivateMessage.find(params[:private_message_id])
      #  @messages = reply_chain(@reply)
      #end
#    else
#    end
#  end
  
  def new
    @message = PrivateMessage.new
  end

  def create
    users = User.where(id: params[:to_user])
    @message = PrivateMessage.create(params_for_create_message)
    if @message.valid?
      @message.user_messages.create({user_id: current_user.id, method: "From"})
      users.each do |user|
        @message.user_messages.create!({user_id: user.id, method: "To"})
        user.notify("#{current_user.to_s} sent you a message.", @message, "message")
      end
      #"#{@message.sent_by} sent you a message at #{@message.created_at.to_formatted_s(:long)}.<blockquote>#{@message.message.at(0..100)}</blockquote>"
      redirect_to @message
    else
      flash[:error] = "Invalid message.  Both a message and a title are required."
      redirect_to new_message_path
    end
  end

  def show
    @previous = []
    p = @message.private_message
    while p do
      @previous.unshift(p)
      p = p.private_message
    end
    if current_user.private_messages.received.include? @message
      @message.user_messages.where(user: current_user)[0].update!(unread: false)
    end
  end

  def destroy
    @message.user_messages.where(user_id: current_user.id).each do |um|
      um.destroy
    end
    if @message.user_messages.count <= 0
      @message.destroy
    end
    flash[:error] = "Message deleted."
    redirect_to private_messages_path
    # how should this be handled?!
  end

  private

  def params_for_create_message
    params.permit(:message, :title, :private_message_id)
  end

  def set_model
    @message = PrivateMessage.find(params[:id])
    if not @message.users.include?(current_user)
      @message = nil
      flash[:error] = "You are not authorized to access this page."
      redirect_to dashboard_path
    end
  end

end