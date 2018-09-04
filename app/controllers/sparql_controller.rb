class SparqlController < ApplicationController
  def index
  	@pages = Page.where(category: "sparql")
  end
end
