
class ReportsController < ApplicationController

  def artists
    @artists = Artist.where("name not like '%?%'").order("name")
  end

end
