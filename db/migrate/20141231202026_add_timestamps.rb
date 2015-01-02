class AddTimestamps < ActiveRecord::Migration
  def change

    # use Rails timestamp fieldname conventions in all tables
    #
    # we timestamp everything, since we get it for free, but
    # typically, we'll only have created_by and updated_by fields on
    # main entities (not join tables)

    add_column(:agents, :created_at, :datetime)
    add_reference(:agents, :created_by, index: true)
    add_column(:agents, :updated_at, :datetime)
    add_reference(:agents, :updated_by, index: true)

    add_column(:artists, :created_at, :datetime)
    add_reference(:artists, :created_by, index: true)
    add_column(:artists, :updated_at, :datetime)
    add_reference(:artists, :updated_by, index: true)

    add_column(:authors, :created_at, :datetime)
    add_reference(:authors, :created_by, index: true)
    add_column(:authors, :updated_at, :datetime)
    add_reference(:authors, :updated_by, index: true)

    remove_column(:entries, :added_on)
    remove_column(:entries, :added_by_id)
    remove_column(:entries, :last_modified)
    remove_column(:entries, :last_modified_by_id)
    add_column(:entries, :created_at, :datetime)
    add_reference(:entries, :created_by, index: true)
    add_column(:entries, :updated_at, :datetime)
    add_reference(:entries, :updated_by, index: true)

    add_column(:entry_artists, :created_at, :datetime)
    add_column(:entry_artists, :updated_at, :datetime)

    remove_column(:entry_comments, :added_on)
    remove_column(:entry_comments, :added_by_id)
    add_column(:entry_comments, :created_at, :datetime)
    add_reference(:entry_comments, :created_by, index: true)
    add_column(:entry_comments, :updated_at, :datetime)
    add_reference(:entry_comments, :updated_by, index: true)

    add_column(:entry_dates, :created_at, :datetime)
    add_column(:entry_dates, :updated_at, :datetime)

    add_column(:entry_languages, :created_at, :datetime)
    add_column(:entry_languages, :updated_at, :datetime)

    add_column(:entry_materials, :created_at, :datetime)
    add_column(:entry_materials, :updated_at, :datetime)

    add_column(:entry_places, :created_at, :datetime)
    add_column(:entry_places, :updated_at, :datetime)

    add_column(:entry_scribes, :created_at, :datetime)
    add_column(:entry_scribes, :updated_at, :datetime)

    add_column(:entry_titles, :created_at, :datetime)
    add_column(:entry_titles, :updated_at, :datetime)

    add_column(:entry_uses, :created_at, :datetime)
    add_column(:entry_uses, :updated_at, :datetime)

    add_column(:event_agents, :created_at, :datetime)
    add_column(:event_agents, :updated_at, :datetime)

    add_column(:events, :created_at, :datetime)
    add_reference(:events, :created_by, index: true)
    add_column(:events, :updated_at, :datetime)
    add_reference(:events, :updated_by, index: true)

    add_column(:languages, :created_at, :datetime)
    add_reference(:languages, :created_by, index: true)
    add_column(:languages, :updated_at, :datetime)
    add_reference(:languages, :updated_by, index: true)

    add_reference(:manuscripts, :created_by, index: true)
    add_reference(:manuscripts, :updated_by, index: true)

    add_column(:places, :created_at, :datetime)
    add_reference(:places, :created_by, index: true)
    add_column(:places, :updated_at, :datetime)
    add_reference(:places, :updated_by, index: true)

    add_column(:scribes, :created_at, :datetime)
    add_reference(:scribes, :created_by, index: true)
    add_column(:scribes, :updated_at, :datetime)
    add_reference(:scribes, :updated_by, index: true)

    remove_column(:sources, :added_on)
    remove_column(:sources, :added_by_id)
    remove_column(:sources, :last_modified)
    remove_column(:sources, :last_modified_by_id)
    add_column(:sources, :created_at, :datetime)
    add_reference(:sources, :created_by, index: true)
    add_column(:sources, :updated_at, :datetime)
    add_reference(:sources, :updated_by, index: true)

  end
end
