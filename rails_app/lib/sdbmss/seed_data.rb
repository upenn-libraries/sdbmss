# This is a level of indirection for code usually found in db/seeds.rb
# because we want to be able to call this from rspec without having to
# bootstrap rake for the db:seed task.

module SDBMSS
end

require_relative "seed_data/helpers"

module SDBMSS::SeedData
  def self.create
    [
      {
        name: "auction_catalog",
        display_name: "Auction/Dealer Catalog",
        entries_have_institution_field: false,
        entries_transaction_field: "sale"
      },
      {
        name: "collection_catalog",
        display_name: "Collection Catalog",
        entries_have_institution_field: false,
        entries_transaction_field: "no_transaction"
      },
      {
        name: "online",
        display_name: "Online-only Auction or Bookseller Website",
        entries_have_institution_field: false,
        entries_transaction_field: "sale"
      },
      {
        name: "observation",
        display_name: "Personal Observation",
        entries_have_institution_field: false,
        entries_transaction_field: "choose"
      },
      {
        name: "other_published",
        display_name: "Other Published Source",
        entries_have_institution_field: true,
        entries_transaction_field: "choose"
      },
      {
        name: "unpublished",
        display_name: "Unpublished",
        entries_have_institution_field: true,
        entries_transaction_field: "choose"
      }
    ].each do |attrs|
      SourceType.find_or_create_by!(name: attrs[:name]) do |source_type|
        source_type.display_name = attrs[:display_name]
        source_type.entries_have_institution_field = attrs[:entries_have_institution_field]
        source_type.entries_transaction_field = attrs[:entries_transaction_field]
      end
    end

    find_or_create_user(
      username: "admin",
      password: "somethingunguessable",
      email: "admin@1.com",
      role: "admin"
    )

    find_or_create_user(
      username: "contributor",
      password: "somethingunguessable",
      email: "contributor@1.com",
      role: "contributor"
    )

    [
      ["Source Instructions", "source_instructions.html"],
      ["Source Overview", "source_overview.html"],
      ["Entry Instructions", "entry_instructions.html"],
      ["Bookmark Instructions", "bookmark_instructions.html"],
      ["Home Text", "home_text.html"],
      ["Linking Tool Entry Instructions", "linking_tool_entry_instructions.html"],
      ["Linking Tool Manuscript Instructions", "linking_tool_manuscript_instructions.html"],
      ["Groups Instructions", "groups_instructions.html"],
      ["Place Instructions", "place_instructions.html"],
      ["Language Instructions", "language_instructions.html"],
      ["Name Instructions", "name_instructions.html"],
      ["Manuscript Instructions", "manuscript_instructions.html"],
      ["Watches Instructions", "watches_instructions.html"],
      ["De Ricci Archive", "de_ricci_archive.html"],
      ["De Ricci Game Description", "de_ricci_game_description.html"],
      ["De Ricci Game Instructions", "de_ricci_game_instructions.html"],
      ["De Ricci Game Results", "de_ricci_game_results.html"],
      ["De Ricci Game FAQ", "de_ricci_game_faq.html"],
      ["Exports Instructions", "exports_instructions.html"]
    ].each do |name, filename|
      find_or_create_page(name, filename)
    end
  end
end
