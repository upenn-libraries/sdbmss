
# Base controller to provide data management functions for Models with
# just a name field. This is used for Languages and Places.
class SimpleNamedModelsController < ApplicationController
  include ResourceSearch

  before_action :set_model, only: [:show, :show_json, :edit, :update, :destroy]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

  respond_to :html, :json

  # Subclasses must implement this and return a Model class for the
  # controller
  def model_class
    raise "model_class not implemented"
  end

  def model_class_lstr
    model_class.to_s.downcase
  end

  def index
  end

  def new
    @model = model_class.new
  end

  def create
    error = nil
    @model = model_class.new(model_params)
    begin
      @model.save!
    rescue Exception => e
      error = e.to_s
    end
    respond_to do |format|
      format.html {
        respond_with(@model)
      }
      format.json {
        if !error
          render json: @model
        else
          render json: { error: error }, status: :unprocessable_entity
        end
      }
    end
  end

  def update
    @model.update(model_params)

    respond_to do |format|
      format.html {
        flash[:notice] = "Your changes have been saved."
        redirect_to :action => "edit", :id => @model.id
      }
      format.json {
        render json: @model
      }
    end
  end

  def destroy
    # mark as deleted, don't actually destroy the record
    @model.deleted = true
    @model.save!
    respond_with(@model)
  end

  private

  def set_model
    @model = model_class.find(params[:id])
  end

  def model_params
    params.require(model_class_lstr.to_sym).permit(:name)
  end

  # _path helpers are usually automatically added to controllers by
  # route configuration. We want these 'generic' paths to delegate to
  # subclasses.

  def models_path
    send((model_class_lstr.pluralize + "_path").to_sym)
  end

  def new_model_path
    send(("new_" + model_class_lstr + "_path").to_sym)
  end

  def edit_model_path(id)
    send(("edit_" + model_class_lstr + "_path").to_sym, id)
  end

  def model_path(id)
    send((model_class_lstr + "_path").to_sym, id)
  end

  helper_method :models_path, :new_model_path, :edit_model_path, :model_path, :model_class

end
