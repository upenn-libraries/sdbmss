class DericciSalesController < ApplicationController

  def index
    @sales = DericciSale.all
  end

end