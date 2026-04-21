FactoryBot.define do

  factory :edit_test_source, aliases: [:source], class: Source do
    title { "A Sample Test Source With a Highly Unique Name" }
    date { "2013-11-12" }
    source_type { SourceType.auction_catalog }
    created_by { create(:admin) }

    after(:create) do |source|
      next if source.source_agents.exists?
      
      role = if source.source_type&.name == SourceType::COLLECTION_CATALOG
        SourceAgent::ROLE_INSTITUTION
      else
        SourceAgent::ROLE_SELLING_AGENT
      end

      source.source_agents.create!(
        role: role,
        agent: Name.find_or_create_agent("Sotheby's")
      )
    end
  end

end
