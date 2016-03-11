# This representation tries to mirror the table structure as closely
# as possible, to facilitate using the same representation for
# updating the database.

json.(@entry, :id, :folios, :catalog_or_lot_number, :transaction_type, :folios, :num_columns, :num_lines, :height, :width, :alt_size, :manuscript_binding, :other_info, :manuscript_link, :miniatures_fullpage, :miniatures_large, :miniatures_small, :miniatures_unspec_size, :initials_historiated, :initials_decorated, :deprecated, :superceded_by_id)

json.cumulative_updated_at @entry.cumulative_updated_at

json.created_by @entry.created_by.username
json.created_at @entry.created_at.to_formatted_s(:date_and_time)

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
  json.entry_titles @entry.entry_titles.order(:order) do |entry_title|
    json.(entry_title, :id, :order, :title, :common_title, :uncertain_in_source, :supplied_by_data_entry)
  end
end

if @entry.entry_authors.present?
  json.entry_authors @entry.entry_authors.order(:order) do |entry_author|
    json.(entry_author, :id, :order, :observed_name, :role, :uncertain_in_source, :supplied_by_data_entry)
    if entry_author.author
      json.author do
        json.(entry_author.author, :id, :name)
      end
    end
  end
end

if @entry.entry_dates.present?
  json.entry_dates @entry.entry_dates.order(:order) do |entry_date|
    json.(entry_date, :id, :order, :observed_date, :date_normalized_start, :date_normalized_end, :uncertain_in_source, :supplied_by_data_entry)
  end
end

if @entry.entry_artists.present?
  json.entry_artists @entry.entry_artists.order(:order) do |entry_artist|
    json.(entry_artist, :id, :order, :observed_name, :uncertain_in_source, :supplied_by_data_entry)
    if entry_artist.artist
      json.artist do
        json.(entry_artist.artist, :id, :name)
      end
    end
  end
end

if @entry.entry_scribes.present?
  json.entry_scribes @entry.entry_scribes.order(:order) do |entry_scribe|
    json.(entry_scribe, :id, :order, :observed_name, :uncertain_in_source, :supplied_by_data_entry)
    if entry_scribe.scribe
      json.scribe do
        json.(entry_scribe.scribe, :id, :name)
      end
    end
  end
end

if @entry.entry_languages.present?
  json.entry_languages @entry.entry_languages.order(:order) do |entry_language|
    json.(entry_language, :id, :order, :uncertain_in_source, :supplied_by_data_entry)
    if entry_language.language
      json.language do
        json.(entry_language.language, :id, :name)
      end
    end
  end
end

if @entry.entry_materials.present?
  json.entry_materials @entry.entry_materials.order(:order) do |entry_material|
    json.(entry_material, :id, :order, :material, :uncertain_in_source, :supplied_by_data_entry)
  end
end

if @entry.entry_places.present?
  json.entry_places @entry.entry_places.order(:order) do |entry_place|
    json.(entry_place, :id, :order, :observed_name, :uncertain_in_source, :supplied_by_data_entry)
    if entry_place.place
      json.place do
        json.(entry_place.place, :id, :name)
      end
    end
  end
end

if @entry.entry_uses.present?
  json.entry_uses @entry.entry_uses.order(:order) do |entry_use|
    json.(entry_use, :id, :order, :use)
  end
end

# structurally in the db, Entry -> Sale is a One -> Many relationship
# (an artifact of some refactoring) but we provide it as a single hash
# here, instead of an array with one item.
if @entry.get_sale.present?
  json.sale do
    json.(@entry.get_sale, :id, :date, :price, :currency, :other_currency, :sold)
    if @entry.get_sale.sale_agents.present?
      json.sale_agents @entry.get_sale.sale_agents do |sale_agent|
        json.(sale_agent, :id, :observed_name, :role, :uncertain_in_source, :supplied_by_data_entry)
        if sale_agent.agent
          json.agent do |agent|
            json.(sale_agent.agent, :id, :name)
          end
        end
      end
    end
  end
end

if @entry.provenance.present?
  json.provenance @entry.provenance.order(:order) do |provenance_item|
    json.(provenance_item, :id, :order, :observed_name, :acquisition_method, :direct_transfer, :comment, :start_date, :end_date, :uncertain_in_source, :supplied_by_data_entry)
    if provenance_item.associated_date.present?
      json.dates provenance_item.associated_date.split("\t").map { |dt| {date: dt, type: "Associated"} }  + [{date: provenance_item.start_date, type: "Start"} ] + [{ date: provenance_item.end_date, type: "End"}]
    end
    json.start_date_normalized_start SDBMSS::Util.format_fuzzy_date(provenance_item.start_date_normalized_start)
    json.start_date_normalized_end SDBMSS::Util.format_fuzzy_date(provenance_item.start_date_normalized_end)
    json.associated_date_normalized_start SDBMSS::Util.format_fuzzy_date(provenance_item.associated_date_normalized_start)
    json.associated_date_normalized_end SDBMSS::Util.format_fuzzy_date(provenance_item.associated_date_normalized_end)
    json.end_date_normalized_start SDBMSS::Util.format_fuzzy_date(provenance_item.end_date_normalized_start)
    json.end_date_normalized_end SDBMSS::Util.format_fuzzy_date(provenance_item.end_date_normalized_end)
    if provenance_item.provenance_agent.present?
      json.provenance_agent do
        json.(provenance_item.provenance_agent, :id, :name)
      end
    end
  end
end

if @entry.entry_comments.present?
  json.entry_comments @entry.entry_comments do |entry_comment|
    json.(entry_comment, :id)
    json.comment do
      json.(entry_comment.comment, :id, :comment)
      json.created_at entry_comment.comment.created_at.to_formatted_s(:date_and_time)
      json.created_by entry_comment.comment.created_by.username
    end
  end
end
