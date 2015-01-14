
describe "SDBMSS::Util" do

   describe "#split_and_strip" do

     it "splits a string" do
       expect(SDBMSS::Util.split_and_strip("One String|Another String")).to eq(["One String", "Another String"])
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

   end

end
