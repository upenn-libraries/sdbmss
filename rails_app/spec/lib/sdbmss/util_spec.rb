
require 'sdbmss/util'
require 'json'

describe "SDBMSS::Util" do

  describe "#format_fuzzy_date" do

    it "formats a basic date" do
      expect(SDBMSS::Util.format_fuzzy_date("20141123")).to eq("2014-11-23")
    end

    it "formats a date without a day" do
      expect(SDBMSS::Util.format_fuzzy_date("20141100")).to eq("2014-11")
    end

    it "formats a date with only year" do
      expect(SDBMSS::Util.format_fuzzy_date("20140000")).to eq("2014")
    end

    it "returns garbage data as-is" do
      expect(SDBMSS::Util.format_fuzzy_date("2014874872488")).to eq("2014874872488")
    end

    it "returns circa date" do
      expect(SDBMSS::Util.format_fuzzy_date("ca. 1830")).to eq("ca. 1830")
    end

  end

  describe "#split_and_strip" do

     it "splits a string" do
       expect(SDBMSS::Util.split_and_strip("One String|Another String")).to eq(["One String", "Another String"])
     end

      it "splits a blank string" do
       expect(SDBMSS::Util.split_and_strip("")).to eq([])
     end

     it "splits a string with different delimiter" do
       expect(SDBMSS::Util.split_and_strip("One String, Another String", delimiter: ",")).to eq(["One String", "Another String"])
       expect(SDBMSS::Util.split_and_strip("One String, Another String|Third String", delimiter: /[\,\|]/)).to eq(["One String", "Another String", "Third String"])
     end

     it "splits a string filtering blanks by default" do
       expect(SDBMSS::Util.split_and_strip("One String||Another String")).to eq(["One String", "Another String"])
       expect(SDBMSS::Util.split_and_strip("One String||Another String|")).to eq(["One String", "Another String"])
     end

     it "splits a string filtering blanks" do
       expect(SDBMSS::Util.split_and_strip("One String||Another String", filter_blanks: false)).to eq(["One String", "", "Another String"])
     end

   end

   describe "#range_bucket" do

     it "returns a range" do
       expect(SDBMSS::Util.range_bucket(1)).to eq("1 - 10")
       expect(SDBMSS::Util.range_bucket(23)).to eq("21 - 30")
       expect(SDBMSS::Util.range_bucket(9999)).to eq("9991 - 10000")
     end

     it "returns a range with a specified bucket size" do
       bucket_size = 50
       expect(SDBMSS::Util.range_bucket(1, bucket_size)).to eq("1 - 50")
       expect(SDBMSS::Util.range_bucket(189, bucket_size)).to eq("151 - 200")
       expect(SDBMSS::Util.range_bucket(9999, bucket_size)).to eq("9951 - 10000")
    end

    describe "#wait_for_solr_to_be_current" do
      it "returns quickly when Solr is already current" do
        fake_response = JSON.generate({
          "status" => {
            "test" => {
              "index" => {
                "current" => true
              }
            }
          }
        })

        allow(Net::HTTP).to receive(:get).and_return(fake_response)
        allow(SDBMSS::Util).to receive(:sleep)

        SDBMSS::Util.wait_for_solr_to_be_current

        expect(SDBMSS::Util).not_to have_received(:sleep)
      end
    end

end

end
