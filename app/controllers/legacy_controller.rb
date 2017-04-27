# handle links from the old dla website

class LegacyController < ApplicationController
  def index
    host = request.host
    forwarded_host = request.env["HTTP_X_FORWARDED_SERVER"]
    # if we are not on sdbm... already
    if host != forwarded_host
      entry_id = params[:id].to_s.gsub('SCHOENBERG_', '')
      if Entry.exists? entry_id
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
        redirect_to entry_url(entry_id).gsub(host, forwarded_host), status: 301
      else
        # redirect to landing page (same page, with new host)
        redirect_to request.url.gsub(host, forwarded_host), status: 301
      end
    else
      entry_id = params[:id].to_s.gsub('SCHOENBERG_', '')
      if Entry.exists? entry_id
        #shouldn't be here, though
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
        redirect_to entry_url(entry_id).gsub(host, forwarded_host), status: 301
      else
        # renders legacy/index        
      end
    end
  end
end