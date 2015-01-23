
# These are factories that produce "reference data": entries from
# actual catalogs. This gives us a record, in code, of where various
# bits of data live in the database schema, for different types of
# entries.

FactoryGirl.define do

  factory :jonathan_a_hill_catalog_one, parent: :entry do
    association :source, factory: :source
    # TODO
  end

end
