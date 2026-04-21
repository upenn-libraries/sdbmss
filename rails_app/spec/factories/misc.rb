FactoryBot.define do
  factory :watch do
    association :user
    association :watched, factory: :entry
  end

  factory :private_message do
    created_by { create(:user) }
    title { "Test Subject" }
    message { "Test Body" }
  end

  factory :user_message do
    association :private_message
    association :user
  end

  factory :comment do
    association :commentable, factory: :entry
    comment { "Test Comment" }
    created_by { create(:user) }
  end

  factory :entry_change do
    entry
    changed_by { create(:user) }
  end
end
