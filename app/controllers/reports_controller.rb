
class ReportsController < ApplicationController

  before_action :authenticate_user!

  def artists
    @artists = Artist.where("name not like '%?%'").order("name")
  end

  def authors
    @authors = Author.where("name not like '%?%'").order("name")
  end

end
