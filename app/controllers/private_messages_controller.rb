class Chain
  attr_accessor :messages

  def initialize(message, user)
    @messages = []
    # climb up to the beginning of the chain, adding each 'previous'
    while message.private_message do
      message = message.private_message
      @messages |= [message]
    end
    # traverse the 'tree' from the root, adding all replies directed to that user
    compile_messages(message, user)

    # message 'tree' is flattened and sorted by date
    @messages = @messages.sort { |a, b| a.created_at <=> b.created_at }
  end

  def compile_messages(message, user)
    # add all the messages in the 'tree' to the message list
    rp = message.replies
    if rp.count > 0
      rp.each { |reply| compile_messages(reply, user) }
    end
    if message.users.include?(user) or message.created_by == user
      @messages |= [message]
    end
  end

  def include?(message)
    @messages.include? message
  end

  def latest(user=nil)
    if not user
      @messages.last
    else
      @messages.select { |msg| msg.created_by == user }.last
    end
  end

  def unread(user)
    @messages.select { |m| m.unread(user) }.count
  end

  def users(user)
    @messages.reverse.map { |m| m.users + [m.created_by] }.flatten.uniq
  end
end

class PrivateMessagesController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show, :new, :create, :edit, :update, :destroy, :search]

  before_action :set_model, only: [:show, :destroy]

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_approved, :deprecate]

  def index
    if params[:sent_by]
      @sent_by = true
      messages = current_user.sent_messages
    else
      messages = current_user.private_messages
    end
    @chains = []
    messages.each do |pm|
      if @chains.select { |ch| ch.include? pm }.count > 0
        # already in a chain, so pass
      else
        chain = Chain.new(pm, current_user)
        @chains.push(chain)
      end
    end
    @page = params[:page].to_i
    @total = @chains.count
    @per_page = 10
    @chains = @chains.sort { |a, b| b.latest.created_at <=> a.latest.created_at }[(@page * @per_page)..(@page * @per_page + @per_page)]
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
        user.notify("#{current_user.to_s} sent you a message.", @message, "message")
      end
      respond_to do |format|
        format.html {
          flash[:success] = "Message sent to #{users.map(&:username).join(', ')}."
          redirect_to @message          
        }
        format.json {
          render json: {message: "Message sent successfully", status: "success"}
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = "Invalid message.  Both a message and a title are required."
          redirect_to new_message_path
        }
        format.json {
          render json: {message: "Message could not be sent", status: "failure"}
        }
      end
    end
  end

  def show
    @chain = Chain.new(@message, current_user)
    @chain.messages.each { |message| message.delay.read(current_user) }
  end

  # fix me: this is not accessible anyway, not really needed (at the moment) - no great way of handling it atm either
  def destroy
    @message.user_messages.where(user_id: current_user.id).each do |um|
      um.destroy!
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