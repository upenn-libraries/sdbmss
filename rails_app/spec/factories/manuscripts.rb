FactoryBot.define do

  factory :manuscript do
    created_by { create(:admin) }
    updated_by { created_by }
  end

  factory :entry_manuscript do
    association :entry, factory: :edit_entry_with_titles
    manuscript
    relation_type { EntryManuscript::TYPE_RELATION_IS }
    created_by { manuscript.created_by || create(:admin) }
    updated_by { created_by }
  end

end
