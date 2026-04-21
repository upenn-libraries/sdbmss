FactoryBot.define do
  factory :name do
    sequence(:name) { |n| "Agent Name #{n}" }
    created_by { create(:admin) }
    is_author { true }
  end
end
