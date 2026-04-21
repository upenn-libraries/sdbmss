FactoryBot.define do
  factory :dericci_record do
    name { "De Ricci Record" }
    created_by { create(:admin) }
  end

  factory :dericci_link do
    name
    dericci_record
    created_by { create(:admin) }
  end
end
