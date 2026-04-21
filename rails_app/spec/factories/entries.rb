FactoryBot.define do
  factory :edit_test_entry, aliases: [:entry], class: Entry do
    source { create(:edit_test_source) }
    created_by { source.created_by || create(:admin) }
    approved { false }
    catalog_or_lot_number { "123" }
    folios { 123 }
    num_lines { 3 }
    num_columns { 2 }
    height { 200 }
    width { 300 }
    alt_size { "F" }
    miniatures_fullpage { 6 }
    miniatures_large { 7 }
    miniatures_small { 8 }
    miniatures_unspec_size { 9 }
    initials_historiated { 10 }
    initials_decorated { 11 }
    manuscript_binding { "Velvet" }
    manuscript_link { "http://something.com" }
    other_info { "Other stuff" }

    trait :with_sale do
      after(:create) do |entry|
        sale = entry.sales.create!(
          sold: "Yes",
          date: "20140303",
          price: 130000,
          currency: "USD",
        )
        sale.sale_agents.create!(agent: Name.find_or_create_agent("Sotheby's"), role: SaleAgent::ROLE_SELLING_AGENT)
        sale.sale_agents.create!(agent: Name.find_or_create_agent("Joe2"), role: SaleAgent::ROLE_SELLER_OR_HOLDER)
        sale.sale_agents.create!(agent: Name.find_or_create_agent("Joe3"), role: SaleAgent::ROLE_BUYER)
      end
    end

    trait :with_titles do
      after(:create) do |entry|
        entry.entry_titles.create!(title: "Book of Hours", order: 0)
        entry.entry_titles.create!(title: "Bible", order: 1)
      end
    end

    trait :with_author do
      after(:create) do |entry|
        entry.entry_authors.create!(
          author: Name.find_or_create_agent("Schmoe, Joe"),
          observed_name: "Joe Schmoe",
          role: "Tr",
          uncertain_in_source: true,
          order: 0,
        )
      end
    end

    trait :with_date do
      after(:create) do |entry|
        entry.entry_dates.create!(
          observed_date: "early 15th century",
          date_normalized_start: "1400",
          date_normalized_end: "1426",
          order: 0,
        )
      end
    end

    trait :with_artist do
      after(:create) do |entry|
        entry.entry_artists.create!(
          artist: Name.find_or_create_agent("Schultz, Charles"),
          observed_name: "Chuck",
          order: 0,
        )
      end
    end

    trait :with_scribe do
      after(:create) do |entry|
        entry.entry_scribes.create!(
          scribe: Name.find_or_create_agent("Brother Francis"),
          observed_name: "Brother Francisco",
          order: 0,
        )
      end
    end

    trait :with_language do
      after(:create) do |entry|
        entry.entry_languages.create!(
          language: Language.find_or_create_by(name: "Latin"),
          order: 0,
        )
      end
    end

    trait :with_material do
      after(:create) do |entry|
        entry.entry_materials.create!(
          material: "Parchment",
          order: 0,
        )
      end
    end

    trait :with_place do
      after(:create) do |entry|
        entry.entry_places.create!(
          place: Place.find_or_create_by(name: "Italy, Tuscany, Florence"),
          observed_name: "Somewhere in Italy",
          uncertain_in_source: true,
          order: 0,
        )
      end
    end

    trait :with_use do
      after(:create) do |entry|
        entry.entry_uses.create!(
          use: "Some mysterious office or other",
          order: 0,
        )
      end
    end

    trait :with_provenance do
      after(:create) do |entry|
        entry.provenance.create!(
          observed_name: "Somebody, Joe",
          provenance_agent: Name.find_or_create_agent("Somebody, Joseph"),
          uncertain_in_source: true,
          start_date_normalized_start: "1945-06-15",
          direct_transfer: true,
          order: 0,
        )
        entry.provenance.create!(
          provenance_agent: Name.find_or_create_agent("Sotheby's"),
          comment: "An historic sale",
          direct_transfer: true,
          order: 1,
        )
        entry.provenance.create!(
          observed_name: "Wild Bill Collector",
          comment: "This is some unknown dude",
          order: 2,
        )
      end
    end

    trait :fully_loaded_for_edit do
      with_sale
      with_titles
      with_author
      with_date
      with_artist
      with_scribe
      with_language
      with_material
      with_place
      with_use
      with_provenance
    end
  end

  factory :edit_entry_with_titles, class: Entry do
    transient do
      titles { ["Book of Hours"] }
      include_author { true }
    end

    source { create(:edit_test_source) }
    created_by { source.created_by || create(:admin) }
    approved { false }
    catalog_or_lot_number { "123" }

    after(:create) do |entry, evaluator|
      evaluator.titles.each_with_index do |title, index|
        entry.entry_titles.create!(title: title, order: index)
      end

      if evaluator.include_author
        entry.entry_authors.create!(
          author: Name.find_or_create_agent("Schmoe, Joe"),
          observed_name: "Joe Schmoe",
          order: 0,
        )
      end
    end
  end

end
