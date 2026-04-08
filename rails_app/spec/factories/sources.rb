FactoryGirl.define do

  factory :edit_test_source, class: Source do
    title "A Sample Test Source With a Highly Unique Name"
    date "2013-11-12"
    source_type { SourceType.auction_catalog }
    created_by { User.where(role: 'admin').first || create(:admin) }

    after(:create) do |source|
      next if source.source_agents.exists?(role: SourceAgent::ROLE_SELLING_AGENT)

      source.source_agents.create!(
        role: SourceAgent::ROLE_SELLING_AGENT,
        agent: Name.find_or_create_agent("Sotheby's")
      )
    end
  end

end
