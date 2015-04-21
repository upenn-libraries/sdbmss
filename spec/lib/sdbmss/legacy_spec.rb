
require 'sdbmss'
require "rails_helper"

describe "SDBMSS::Legacy" do

   describe "#split_author_role_code" do

     it "splits an author without a code" do
       expect(SDBMSS::Legacy.split_author_role_codes("Jeff")).to eq(["Jeff", []])
     end

     it "splits an author with a code" do
       expect(SDBMSS::Legacy.split_author_role_codes("Jerome, Saint (Ed)")).to eq(["Jerome, Saint", ["Ed"]])
     end

     it "splits an author with two codes" do
       expect(SDBMSS::Legacy.split_author_role_codes("Jerome, Saint (Ed) (Tr)")).to eq(["Jerome, Saint", ["Ed", "Tr"]])
     end

     it "splits an author with a code and some other junk" do
       expect(SDBMSS::Legacy.split_author_role_codes("Francesco Accolti (Aretino) (Tr)")).to eq(["Francesco Accolti (Aretino)", ["Tr"]])
     end

   end

   describe "#parse_certainty_indicators" do

     it "leaves weird data alone" do
       expect(SDBMSS::Legacy.parse_certainty_indicators(nil)).to eq([nil, false, false])
       expect(SDBMSS::Legacy.parse_certainty_indicators("")).to eq(["", false, false])
       expect(SDBMSS::Legacy.parse_certainty_indicators("Hello there")).to eq(["Hello there", false, false])
       expect(SDBMSS::Legacy.parse_certainty_indicators("[Hello there")).to eq(["[Hello there", false, false])
       expect(SDBMSS::Legacy.parse_certainty_indicators("Hello there]")).to eq(["Hello there]", false, false])
       expect(SDBMSS::Legacy.parse_certainty_indicators("[Hello] there")).to eq(["[Hello] there", false, false])
   end

     it "parses expected cases properly" do
       expect(SDBMSS::Legacy.parse_certainty_indicators("[Hello there]")).to eq(["Hello there", false, true])
       expect(SDBMSS::Legacy.parse_certainty_indicators("Hello there?")).to eq(["Hello there", true, false])
       expect(SDBMSS::Legacy.parse_certainty_indicators("Hello there ?")).to eq(["Hello there", true, false])
       expect(SDBMSS::Legacy.parse_certainty_indicators("Hello? there?")).to eq(["Hello? there", true, false])
       expect(SDBMSS::Legacy.parse_certainty_indicators("[Hello there?]")).to eq(["Hello there", false, true])
       expect(SDBMSS::Legacy.parse_certainty_indicators("[Hello there]?")).to eq(["Hello there", false, true])
     end

   end

   describe "#parse_common_title" do

     it "parses common titles properly" do
       expect(SDBMSS::Legacy.parse_common_title("Hello there")).to eq(["Hello there", nil])
       expect(SDBMSS::Legacy.parse_common_title("xyz [Hello there]")).to eq(["xyz", "Hello there"])
       # this is an actual title from record 67358!
       expect(SDBMSS::Legacy.parse_common_title("Commentary On [Pseudo-] Dionysius [The Areopagite] Opera")).to eq(["Commentary On [Pseudo-] Dionysius [The Areopagite] Opera", nil])
     end

   end

   describe "#normalize_circa_and_date" do

     it "parses normalizes dates properly" do
       expect(SDBMSS::Legacy.normalize_circa_and_date("CCENT", "1550")).to eq(["1500", "1599"])
       # TODO: is this really right?
       expect(SDBMSS::Legacy.normalize_circa_and_date("CCENT", "1200")).to eq(["1200", "1299"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("C1H", "1250")).to eq(["1200", "1250"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("C2H", "1250")).to eq(["1250", "1299"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("C1Q", "1250")).to eq(["1200", "1225"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("C2Q", "1250")).to eq(["1226", "1250"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("C3Q", "1250")).to eq(["1251", "1275"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("C4Q", "1250")).to eq(["1276", "1299"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("CEARLY", "350")).to eq(["300", "350"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("CMID", "350")).to eq(["325", "375"])
       expect(SDBMSS::Legacy.normalize_circa_and_date("CLATE", "350")).to eq(["350", "399"])
     end

   end

end
