# handle links from the old dla website

class LegacyController < ApplicationController
  def index
    host = request.host
    forwarded_host = request.env["HTTP_X_FORWARDED_SERVER"]
    # if we are not on sdbm... already
    if host != forwarded_host
      redirect_to request.url.gsub(host, forwarded_host)
    else
      # combine into (above) to have single redirect
      entry_id = params[:id].to_s.gsub('SCHOENBERG_', '')
      flash[:announce] = %q(
        <div class='text-center'>
          <span class='h3' style='color: #cc0000;'>Welcome to the New Schoenberg Database!</span><br>
          <p class='text-left'>
            The New Schoenberg Database of Manuscripts, in development since 2014, allows you -- the members of its user community -- 
            to become active, contributing partners in its development. Users can add entries, comment on other users entries, aggregate 
            entries to created “manuscript records,” and help us build an authority file of persons and institutions associated 
            with the movement of manuscripts across time and place.
          </p>
          <a href="/pages/About">Learn more</a>
        </div>
      ).html_safe
      #pry.binding
      if Entry.exists?(id: entry_id)
        redirect_to entry_path(Entry.find(entry_id)), status: 301
      else
        redirect_to root_path, status: 301
      end
    end
  end
end