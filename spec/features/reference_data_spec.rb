
require "rails_helper"

require "sdbmss/reference_data"

describe "Reference data" do

  describe "should create all reference data" do
    SDBMSS::ReferenceData.create_all
  end

end
