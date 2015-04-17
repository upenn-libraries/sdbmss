
require 'sdbmss'

class EntryDatesController < ApplicationController

  def normalize
    date_str = params[:date]

    date_start, date_end = nil, nil

    if SDBMSS::Util.resembles_approximate_date_str(date_str)
      date = SDBMSS::Util.normalize_approximate_date_str_to_year_range(date_str)
      date_start = date[0]
      date_end = date[1]
    else
      parsed = Chronic.parse(date_str)
      if parsed.present?
        date_start = parsed.strftime("%Y-%m-%d")
        date_end = date_start
      end
    end

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
