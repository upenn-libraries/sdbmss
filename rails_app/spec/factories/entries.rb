FactoryGirl.define do

  factory :edit_entry_with_titles, class: Entry do
    transient do
      titles ["Book of Hours"]
      include_author true
    end

    source { create(:edit_test_source) }
    created_by { source.created_by || User.where(role: 'admin').first || create(:admin) }
    approved false
    catalog_or_lot_number "123"

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
