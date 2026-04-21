FactoryBot.define do
  factory :language do
    sequence(:name) { |n| "Language #{n}" }
    created_by { create(:admin) }
  end
end
