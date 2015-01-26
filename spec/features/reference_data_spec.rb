
require "rails_helper"

require "sdbmss/reference_data"

describe "Reference data" do

  describe "should create Jonathan Hill catalog and entries" do
    SDBMSS::ReferenceData::JonathanHill.new
  end

end
