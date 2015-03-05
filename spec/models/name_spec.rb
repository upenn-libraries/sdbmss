
require "rails_helper"

describe Name do

  describe "methods" do

    it "should get suggestions" do
      suggestions = Name.suggestions("William Shakespeare")
      expect(suggestions[:already_exists]).to eq(false)
      expect(suggestions[:results].length).to be > 0
      expect(suggestions[:results].first[:name]).not_to be_nil
      expect(suggestions[:results].first[:viaf_id]).not_to be_nil
    end

  end

end
