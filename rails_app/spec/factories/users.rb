
FactoryBot.define do

  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { 'somethingreallylong' }
    active { true }
  end

  factory :admin, class: User do
    sequence(:username) { |n| "admin#{n}" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    password 'somethingreallylong'
    active true
    role 'admin'
  end

end
