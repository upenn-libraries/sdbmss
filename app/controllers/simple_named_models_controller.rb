
# Base controller to provide data management functions for Models with
# just a name field. This is used for Languages and Places.
class SimpleNamedModelsController < ApplicationController
  include ResourceSearch

  before_action :set_model, only: [:show, :show_json, :edit, :update, :destroy]

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  respond_to :html, :json

  # Subclasses must implement this and return a Model class for the
  # controller
  def model_class
    raise "model_class not implemented"
  end

  def model_class_lstr
    model_class.to_s.downcase
  end

  # Name of the resource that this controller controls. By default,
  # this is the same as the model class, but subclasses may want to
  # override if the REST resource name isn't the same, for various
  # reasons. This should be plural.
  def resource_name
    model_class_lstr.pluralize
  end

  def index
  end

  def new
    @model = model_class.new
  end

  def create
    @model = model_class.new(model_params)
    @model.created_by = current_user
    if @model.save
      respond_to do |format|
        format.html {
          redirect_to model_path(@model.id)
        }
        format.json {
          render json: @model
        }
      end
    else
      respond_to do |format|
        format.html {
          render 'new'
        }
        format.json {
          render json: @model
        }
      end
    end
  end

  def update
    if model_params[:password].blank?
      result = @model.update_without_password(model_params)
    else
      result = @model.update(model_params)
    end
    if result
      respond_to do |format|
        format.html {
          flash[:notice] = "Your changes have been saved."
          redirect_to :action => "edit", :id => @model.id
        }
        format.json {
          render json: @model
        }
      end
    else
      render 'edit'
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
    send((resource_name + "_path").to_sym)
  end

  def new_model_path
    send(("new_" + resource_name.singularize + "_path").to_sym)
  end

  def edit_model_path(id)
    send(("edit_" + resource_name.singularize + "_path").to_sym, id)
  end

  def model_path(id)
    send((resource_name.singularize + "_path").to_sym, id)
  end

  helper_method :models_path, :new_model_path, :edit_model_path, :model_path, :model_class, :resource_name

end
