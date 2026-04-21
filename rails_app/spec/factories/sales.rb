FactoryBot.define do
  factory :sale do
    entry { create(:edit_test_entry) }
    sold { Sale::TYPE_SOLD_YES }
    price { 1000.00 }
    currency { "USD" }
    created_by { entry&.created_by || create(:admin) }
  end

  factory :sale_agent do
    sale
    role { SaleAgent::ROLE_SELLING_AGENT }
    agent { create(:name) }
    observed_name { "Observed Name" }
  end
end
