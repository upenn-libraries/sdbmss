FactoryBot.define do
  factory :place do
    sequence(:name) { |n| "Place #{n}" }
    created_by { create(:admin) }
  end
end
