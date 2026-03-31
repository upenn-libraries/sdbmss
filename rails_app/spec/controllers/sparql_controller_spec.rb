require 'rails_helper'

RSpec.describe SparqlController, :type => :controller do

  describe "GET index" do
    it "returns http success", :known_failure do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
