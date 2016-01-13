
# Base controller to provide data management actions (listing, edit,
# add, delete). This provides enough functionality for simple Models
# with just a name field, like Languages and Places; other more
# complex models need to subclass this and customize both the actions
# and views.
class ManageModelsController < ApplicationController
  include ResourceSearch
  include ResetReviewedAfterUpdate

  before_action :set_model, only: [:show, :show_json, :edit, :update, :destroy]

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  respond_to :html, :json

  # Subclasses must implement this and return a Model class for the
  # controller
  def model_class
    controller_name.camelize.singularize.constantize
  end

  def model_class_lstr
    model_class.to_s.underscore
  end

  def model_object_for_reset_reviewed_after_update
    @model
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
    if model_class.column_names.include?("created_by_id")
      result = @model.save_by(current_user)
    else
      result = @model.save
    end
    if result
      respond_to do |format|
        format.html {
          redirect_to model_path(@model.id)
        }
        format.json {
          render json: @model
        }
      end
    else
      # if creating new NAME, and NAME already exists, simply create ERROR (no merge)
      respond_to do |format|
        format.html {
          render 'new'
        }
        format.json {
          render status: :bad_request, json: { errors: @model.errors.messages }
        }
      end
    end
  end

  def update
    result = do_update
    if result
      respond_to do |format|
        format.html {
          flash[:notice] = "Your changes have been saved. It may take a minute or two for your changes to show up in the public search results."
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

  def do_update
    @model.update_by(current_user, model_params)
  end

  def destroy
    # mark as deleted, don't actually destroy the record
    if deletable?(@model)
      @model.deleted = true
      if @model.save
        respond_to do |format|
          format.json {
            render status: :ok, json: {}
          }
        end
      else
        respond_to do |format|
          format.json {
            render status: :unprocessable_entity, json: { "error" => @model.errors.join("; ") }
          }
        end
      end
    else
      respond_to do |format|
        format.json {
          render status: :unprocessable_entity, json: { "error" => "Record is not deletable, probably because other records are associated with it" }
        }
      end
    end
  end

  # extend from superclass to modify query based on these URL params
  # (which are set from JS in views for this controller and its
  # subclasses):
  #
  # 'unreviewed_only' = if set to 1, only returns unreviewed records
  # 'created_by_user' = if set to 1, only returns records created by current user
  def search_query
    query = super
    if params[:created_by_user].to_s == '1'
      query = query.where(created_by_id: current_user.id)
    end
    if params[:unreviewed_only].to_s == '1'
      query = query.where(reviewed: false)
    end
    query
  end

  private

  def set_model
    @model = model_class.find(params[:id])
  end

  def model_params
    params.require(model_class_lstr.to_sym).permit(:name)
  end

  # this implementation checks the entries_count field if it exists
  def deletable?(object)
    deletable = true
    if object.respond_to?(:entries_count) && (object.entries_count || 0)  > 0
      deletable = false
    end
    deletable
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
