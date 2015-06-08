
require "rails_helper"

describe Comment do

  describe "methods" do

    it "should use scope with_entries_belonging_to" do
      user = User.create!(
        email: 'testuser@test.com',
        username: 'adminuser',
        password: 'somethingunguessable',
        role: 'admin'
      )
      Comment.with_entries_belonging_to(user)
    end

  end

end
