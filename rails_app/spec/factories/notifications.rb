FactoryBot.define do
  factory :notification do
    message { "A notification message" }
    category { "test" }
    active { true }
    association :user
    title { "Notification Title" }
  end
end
