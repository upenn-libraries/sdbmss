
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
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, nil, "1272")).to eq(["1272", "1273", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "CCENT", "850")).to eq(["800", "900", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "CCENT", "1550")).to eq(["1500", "1600", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "CCENT", "1200")).to eq(["1200", "1300", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "ccent-?", "1200")).to eq(["1200", "1300", true, false])
       # we take ccent+ to mean the century in question and the next century
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "ccent+", "1150")).to eq(["1100", "1300", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "C1H", "1250")).to eq(["1200", "1251", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "c1h+", "1250")).to eq(["1200", "1300", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "C2H", "1250")).to eq(["1251", "1300", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "c2h+?", "1250")).to eq(["1251", "1351", true, false])
       # a date (nonsensically) outside the circa's period normalizes to just the date
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "C1Q", "1268")).to eq(["1268", "1269", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "C1Q", "1221")).to eq(["1200", "1226", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "C1Q", "1250")).to eq(["1200", "1226", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "C2Q", "1250")).to eq(["1226", "1251", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "C3Q", "1250")).to eq(["1251", "1276", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "C4Q", "1250")).to eq(["1276", "1300", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "CEARLY?", "350")).to eq(["300", "326", true, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "CEARLY", "350")).to eq(["300", "326", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "CMID", "350")).to eq(["326", "376", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "CLATE", "350")).to eq(["376", "400", false, false])
       expect(SDBMSS::Legacy.normalize_circa_and_date(nil, "unrecognized_code", "350")).to eq(["350", "351", false, false])
     end

   end

end
