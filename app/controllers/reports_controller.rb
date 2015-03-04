
require 'delegate'

class ReportsController < ApplicationController

  before_action :authenticate_user!

  def languages
    object_id_and_name(Language)
  end

  def names
    object_id_and_name(Name)
  end

  def places
    object_id_and_name(Place)
  end

  def sources
    object_id_and_name(Source, name_field: 'title')
  end

  private

  # Wraps a model object, providing a #name method that calls the
  # passed-in fieldname accessor
  class ObjectWrapper < SimpleDelegator
    def initialize(obj, fieldname)
      super(obj)
      @fieldname = fieldname
    end
    def name
      send(@fieldname.to_sym)
    end
  end

  def object_id_and_name(model_class, name_field: 'name')

    @object_class = model_class
    @objects = model_class.order(name_field)

    @objects = @objects.map { |obj| ObjectWrapper.new(obj, name_field) } if name_field != 'name'

    respond_to do |format|
      format.html { render "objects.html" }
      format.csv do
        render csv: @objects,
               filename: "#{@object_class.to_s.downcase.pluralize}.csv",
               headers: ['ID', "#{@object_class.to_s} #{name_field}"],
               format: ->(object) { [object.id, object.name] }
      end
    end
  end

end
