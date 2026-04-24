require "rails_helper"

RSpec.describe "DebugController", type: :request do
  describe "GET /raise_error" do
    it "raises a RuntimeError" do
      expect { get "/raise_error/" }.to raise_error(RuntimeError, "This is an error!")
    end
  end
end
