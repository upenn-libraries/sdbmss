FactoryBot.define do
  factory :source_type do
    sequence(:name) { |n| "source_type_#{n}" }
    display_name { name.humanize }
    entries_transaction_field { "choose" }
    entries_have_institution_field { true }
  end
end
