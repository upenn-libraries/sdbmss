
class ReportsController < ApplicationController

  before_action :authenticate_user!

  def agents
    object_id_and_name(Agent)
  end

  def artists
    object_id_and_name(Artist)
  end

  def authors
    object_id_and_name(Author)
  end

  def languages
    object_id_and_name(Language)
  end

  def scribes
    object_id_and_name(Scribe)
  end

  private

  def object_id_and_name model_class
    # TODO: we filter out ? for now; eventually that data should be cleaned up
    @objects = model_class.where("name not like '%?%'").order("name")
    respond_to do |format|
      format.html { render "objects.html" }
      format.csv do
        render csv: @objects,
               filename: "#{model_class.to_s.downcase.pluralize}.csv",
               headers: ['ID', "#{model_class.to_s} Name"],
               format: ->(object) { [object.id, object.name] }
      end
    end
  end

end
