
require 'sdbmss'

class EntryDatesController < ApplicationController

  def parse_observed_date
    date_str = params[:date]

    date_start, date_end = EntryDate.parse_observed_date(date_str)

    respond_to do |format|
      format.json {
        render json: {
                 date: {
                   string: date_str,
                   date_start: date_start,
                   date_end: date_end
                 }
               }, status: :ok
      }
    end
  end

end
