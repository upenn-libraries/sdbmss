
FactoryGirl.define do

  factory :user do
    email 'test@test.com'
    password 'somethingreallylong'
  end

  factory :admin, class: User do
  end

end
