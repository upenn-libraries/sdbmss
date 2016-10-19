class PrivateMessagesController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show, :new, :create, :edit, :update, :destroy, :search]

  before_action :set_model, only: [:show, :destroy]

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_approved, :deprecate]

  def index
    if params[:sent_by]
      @sent_by = true
      @messages = current_user.sent_messages
    else
      #ids = (current_user.private_messages.pluck(:private_message_id) | current_user.sent_messages.pluck(:private_message_id)).compact
      @messages = current_user.private_messages
    end
  end
  
  def new
    @message = PrivateMessage.new
  end

  def create
    users = User.where(id: params[:to_user])
    @message = PrivateMessage.new(params_for_create_message)
    @message.save_by(current_user)
    if @message.valid?
      users.each do |user|
        @message.user_messages.create!({user_id: user.id, method: "To"})
      #  user.notify("#{current_user.to_s} sent you a message.", @message, "message")
      end
      flash[:success] = "Message sent to #{users.map(&:username).join(', ')}."
      redirect_to @message
    else
      flash[:error] = "Invalid message.  Both a message and a title are required."
      redirect_to new_message_path
    end
  end

  def show
    @previous = []
    p = @message.private_message
    if (um = @message.user_messages.where(user: current_user).first)
      um.update(unread: false)
    end
    while p do
      @previous.unshift(p)
      p = p.private_message
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
  end

end