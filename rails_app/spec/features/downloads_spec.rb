# NOTE: because of how asychnronous this is, it seems to be basically untestable using capybara, so....

require "system_helper"

describe "Downloads", :js => true do

  context "when user is logged in " do
    before :all do
      @admin_user = User.where(role: "admin").first
    end

    before :each do
      login(@admin_user, 'somethingunguessable')
    end

  end

end
