
# This is a level of indirection for code usually found in db/seeds.rb
# because we want to be able to call this from rspec without having to
# bootstrap rake for the db:seed task.
module SDBMSS::SeedData

  def self.create

    if SourceType.count == 0
      SourceType.create(
        name: 'auction_catalog',
        display_name: 'Auction/Dealer Catalog',
        entries_have_institution_field: false,
        entries_transaction_field: "sale",
      )

      SourceType.create(
        name: 'collection_catalog',
        display_name: 'Collection Catalog',
        entries_have_institution_field: false,
        entries_transaction_field: "no_transaction",
      )

      SourceType.create(
        name: 'online',
        display_name: 'Online-only Auction or Bookseller Website',
        entries_have_institution_field: false,
        entries_transaction_field: "sale",
      )

      SourceType.create(
        name: 'observation',
        display_name: 'Personal Observation',
        entries_have_institution_field: false,
        entries_transaction_field: "choose",
      )

      SourceType.create(
        name: 'other_published',
        display_name: 'Other Published Source',
        entries_have_institution_field: true,
        entries_transaction_field: "choose",
      )

      SourceType.create(
        name: 'unpublished',
        display_name: 'Unpublished',
        entries_have_institution_field: true,
        entries_transaction_field: "choose",
      )
    end

    User.create!(
      username: 'admin',
      password: 'somethingunguessable',
      email: "admin@1.com",
      role: 'admin'
    )

    User.create!(
      username: 'contributor',
      password: 'somethingunguessable',
      email: "contributor@1.com",
      role: 'contributor'
    )

  end

end
