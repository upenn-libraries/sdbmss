class DericciSalesController < ApplicationController

  def index
    flash.now[:alert] = "<span class='lead'>Warning!</span> The server hosting the De Ricci Digitized Archive is not available.  Our records and workspace will not function correctly.".html_safe
    @sales = DericciSale.all
  end

end