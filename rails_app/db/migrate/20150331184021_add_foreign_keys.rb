class AddForeignKeys < ActiveRecord::Migration
  def change

    add_foreign_key :entry_artists, :entries, on_delete: :cascade
    add_foreign_key :entry_artists, :names, column: :artist_id

    add_foreign_key :entry_authors, :entries, on_delete: :cascade
    add_foreign_key :entry_authors, :names, column: :author_id

    add_foreign_key :entry_changes, :entries, on_delete: :cascade
    add_foreign_key :entry_changes, :users, column: :changed_by_id

    add_foreign_key :entry_comments, :entries, on_delete: :cascade
    add_foreign_key :entry_comments, :users, column: :created_by_id
    add_foreign_key :entry_comments, :users, column: :updated_by_id

    add_foreign_key :entry_dates, :entries, on_delete: :cascade

    add_foreign_key :entry_languages, :entries, on_delete: :cascade
    add_foreign_key :entry_languages, :languages

    add_foreign_key :entry_manuscripts, :entries, on_delete: :cascade
    add_foreign_key :entry_manuscripts, :manuscripts

    add_foreign_key :entry_materials, :entries, on_delete: :cascade

    add_foreign_key :entry_places, :entries, on_delete: :cascade
    add_foreign_key :entry_places, :places

    add_foreign_key :entries, :sources
    add_foreign_key :entries, :users, column: :created_by_id
    add_foreign_key :entries, :users, column: :updated_by_id
    add_foreign_key :entries, :names, column: :institution_id

    add_foreign_key :entry_scribes, :entries, on_delete: :cascade
    add_foreign_key :entry_scribes, :names, column: :scribe_id

    add_foreign_key :entry_titles, :entries, on_delete: :cascade

    add_foreign_key :entry_uses, :entries, on_delete: :cascade

    add_foreign_key :event_agents, :events, on_delete: :cascade
    add_foreign_key :event_agents, :names, column: :agent_id

    add_foreign_key :events, :entries, on_delete: :cascade
    add_foreign_key :events, :users, column: :created_by_id
    add_foreign_key :events, :users, column: :updated_by_id

    add_foreign_key :languages, :users, column: :created_by_id
    add_foreign_key :languages, :users, column: :updated_by_id

    add_foreign_key :manuscript_comments, :manuscripts
    add_foreign_key :manuscript_comments, :users, column: :created_by_id
    add_foreign_key :manuscript_comments, :users, column: :updated_by_id

    add_foreign_key :manuscripts, :users, column: :created_by_id
    add_foreign_key :manuscripts, :users, column: :updated_by_id

    add_foreign_key :names, :entries, on_delete: :cascade
    add_foreign_key :names, :users, column: :approved_by_id
    add_foreign_key :names, :users, column: :created_by_id
    add_foreign_key :names, :users, column: :updated_by_id

    add_foreign_key :places, :entries, on_delete: :cascade
    add_foreign_key :places, :users, column: :approved_by_id
    add_foreign_key :places, :users, column: :created_by_id
    add_foreign_key :places, :users, column: :updated_by_id

    add_foreign_key :source_agents, :sources, on_delete: :cascade
    add_foreign_key :source_agents, :names, column: :agent_id

    add_foreign_key :sources, :users, column: :created_by_id
    add_foreign_key :sources, :users, column: :updated_by_id
    add_foreign_key :sources, :source_types

  end
end
