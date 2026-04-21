FactoryBot.define do
  factory :entry_date do
    entry
    observed_date { "1450" }
    date_normalized_start { 1450 }
    date_normalized_end { 1451 }
  end

  factory :entry_place do
    entry
    place
    observed_name { "Somewhere" }
  end

  factory :name_place do
    name
    place
    notbefore { "1400" }
    notafter { "1500" }
  end

  factory :entry_artist do
    entry
    artist { create(:name) }
    role { "Arti" }
    observed_name { "Artist Name" }
  end
end
