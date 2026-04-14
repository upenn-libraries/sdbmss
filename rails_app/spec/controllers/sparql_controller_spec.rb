require 'rails_helper'

RSpec.describe "Sparql endpoint", :type => :request do
  it "returns http success" do
    get '/sparql-space'
    expect(response).to have_http_status(:success)
  end
end
