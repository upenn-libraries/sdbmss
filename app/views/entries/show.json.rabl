# This representation tries to mirror the table structure as closely
# as possible, to facilitate using the same representation for
# updating the database.
object @entry
attributes :id, :folios, :catalog_or_lot_number, :secondary_source, :folios, :num_columns, :num_lines, :height, :width, :alt_size, :manuscript_binding, :other_info, :manuscript_link, :miniatures_fullpage, :miniatures_large, :miniatures_small, :miniatures_unspec_size, :initials_historiated, :initials_decorated

node :manuscript_id, if: @entry.get_manuscript.present? do
  @entry.get_manuscript.id
end

child :source do
  attributes :id, :title, :date, :source_type, :entries_have_a_transaction
end

child :entry_titles, :object_root => false do
  attributes :id, :title, :common_title, :uncertain_in_source, :supplied_by_data_entry
end

child :entry_authors, :object_root => false do
  attributes :id, :author, :observed_name, :role, :uncertain_in_source, :supplied_by_data_entry
  child :author do
    attributes :id, :name
  end
end

child :entry_dates, :object_root => false do
  attributes :id, :date, :circa
end

child :entry_artists, :object_root => false do
  attributes :id, :uncertain_in_source, :supplied_by_data_entry
  child :artist do
    attributes :id, :name
  end
end

child :entry_scribes, :object_root => false do
  attributes :id, :uncertain_in_source, :supplied_by_data_entry
  child :scribe do
    attributes :id, :name
  end
end

child :entry_languages, :object_root => false do
  attributes :id, :uncertain_in_source, :supplied_by_data_entry
  child :language  do
    attributes :id, :name
  end
end

child :entry_materials, :object_root => false do
  attributes :id, :material, :uncertain_in_source, :supplied_by_data_entry
end

child :entry_places, :object_root => false do
  attributes :id, :uncertain_in_source, :supplied_by_data_entry
  child :place do
    attributes :id, :name
  end
end

child :entry_uses, :object_root => false do
  attributes :id, :use
end

child :events, :object_root => false do
  attributes :id, :primary, :comment, :start_date, :end_date, :price, :currency, :other_currency, :sold
  child :event_agents, :object_root => false do
    attributes :id, :observed_name, :role, :uncertain_in_source, :supplied_by_data_entry
    child :agent do |agent|
      attributes :id, :name
    end
  end
end

child :entry_comments, :object_root => false do
  attributes :id, :comment, :date
  node :created_by do |entry_comment|
    entry_comment.created_by ? "#{entry_comment.created_by.username}" : nil
  end
end
