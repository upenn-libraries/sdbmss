# This representation tries to mirror the table structure as closely
# as possible, to facilitate using the same representation for
# updating the database.

json.(@entry, :id, :folios, :catalog_or_lot_number, :transaction_type, :secondary_source, :folios, :num_columns, :num_lines, :height, :width, :alt_size, :manuscript_binding, :other_info, :manuscript_link, :miniatures_fullpage, :miniatures_large, :miniatures_small, :miniatures_unspec_size, :initials_historiated, :initials_decorated)

json.cumulative_updated_at @entry.cumulative_updated_at

if @entry.institution.present?
  json.institution do
    json.(@entry.institution, :id, :name)
  end
end

if @entry.manuscript.present?
  json.manuscript_id @entry.manuscript.id
end

json.source do
  json.(@entry.source, :id, :display_value, :title, :date, :source_type_id)

  json.source_type do
    json.(@entry.source.source_type, :id, :name, :display_name, :entries_have_institution_field, :entries_transaction_field)
  end
end

if @entry.entry_titles.present?
  json.entry_titles @entry.entry_titles do |entry_title|
    json.(entry_title, :id, :title, :common_title, :uncertain_in_source, :supplied_by_data_entry)
  end
end

if @entry.entry_authors.present?
  json.entry_authors @entry.entry_authors do |entry_author|
    json.(entry_author, :id, :observed_name, :role, :uncertain_in_source, :supplied_by_data_entry)
    if entry_author.author
      json.author do
        json.(entry_author.author, :id, :name)
      end
    end
  end
end

if @entry.entry_dates.present?
  json.entry_dates @entry.entry_dates do |entry_date|
    json.(entry_date, :id, :date, :circa)
  end
end

if @entry.entry_artists.present?
  json.entry_artists @entry.entry_artists do |entry_artist|
    json.(entry_artist, :id, :observed_name, :uncertain_in_source, :supplied_by_data_entry)
    if entry_artist.artist
      json.artist do
        json.(entry_artist.artist, :id, :name)
      end
    end
  end
end

if @entry.entry_scribes.present?
  json.entry_scribes @entry.entry_scribes do |entry_scribe|
    json.(entry_scribe, :id, :observed_name, :uncertain_in_source, :supplied_by_data_entry)
    if entry_scribe.scribe
      json.scribe do
        json.(entry_scribe.scribe, :id, :name)
      end
    end
  end
end

if @entry.entry_languages.present?
  json.entry_languages @entry.entry_languages do |entry_language|
    json.(entry_language, :id, :uncertain_in_source, :supplied_by_data_entry)
    if entry_language.language
      json.language do
        json.(entry_language.language, :id, :name)
      end
    end
  end
end

if @entry.entry_materials.present?
  json.entry_materials @entry.entry_materials do |entry_material|
    json.(entry_material, :id, :material, :uncertain_in_source, :supplied_by_data_entry)
  end
end

if @entry.entry_places.present?
  json.entry_places @entry.entry_places do |entry_place|
    json.(entry_place, :id, :uncertain_in_source, :supplied_by_data_entry)
    if entry_place.place
      json.place do
        json.(entry_place.place, :id, :name)
      end
    end
  end
end

if @entry.entry_uses.present?
  json.entry_uses @entry.entry_uses do |entry_use|
    json.(entry_use, :id, :use)
  end
end

if @entry.events.present?
  json.events @entry.events do |event|
    json.(event, :id, :primary, :comment, :start_date, :end_date, :price, :currency, :other_currency, :sold)
    if event.event_agents.present?
      json.event_agents event.event_agents do |event_agent|
        json.(event_agent, :id, :observed_name, :role, :uncertain_in_source, :supplied_by_data_entry)
        if event_agent.agent
          json.agent do |agent|
            json.(event_agent.agent, :id, :name)
          end
        end
      end
    end
  end
end

if @entry.entry_comments.present?
  json.entry_comments @entry.entry_comments do |entry_comment|
    json.(entry_comment, :id, :comment, :created_at)
    json.created_by entry_comment.created_by.to_s
  end
end
