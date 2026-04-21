FactoryBot.define do
  factory :provenance do
    entry { create(:edit_test_entry) }
    order { 0 }
    observed_name { "Previous Owner" }
  end
end
