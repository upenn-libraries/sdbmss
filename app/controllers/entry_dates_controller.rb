
require 'sdbmss'

class EntryDatesController < ApplicationController

  def normalize
    date_str = params[:date]
    date = SDBMSS::Util.normalize_approximate_date_str(date_str)
    respond_to do |format|
      format.json {
        render json: {
                 date: {
                   string: date_str,
                   date: date
                 }
               }, status: :ok
      }
    end
  end

end
