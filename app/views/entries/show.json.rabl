# This representation tries to mirror the table structure as closely
# as possible, to facilitate using the same representation for
# updating the database.
object @entry
attributes :id, :folios, :date, :catalog_or_lot_number, :secondary_source, :current_location, :folios, :num_columns, :num_lines, :height, :width, :alt_size, :manuscript_binding, :other_info, :manuscript_link, :miniatures_fullpage, :miniatures_large, :miniatures_small, :miniatures_unspec_size, :initials_historiated, :initials_decorated

child :source do
  attributes :id, :title, :date, :source_type
    node :display_value do |source|
      "#{source.get_display_value} (ID: #{source.id})"
    end
end

child :entry_titles, :object_root => false do
  attributes :id, :title, :common_title
end

child :entry_authors, :object_root => false do
  attributes :id, :author, :observed_name, :role
  child :author do
    attributes :id, :name
    node :display_value do |author|
      "#{author.name} (ID: #{author.id})"
    end
  end
end

child :entry_dates, :object_root => false do
  attributes :id, :date, :circa
end

child :entry_artists, :object_root => false do
  attributes :id
  child :artist do
    attributes :id, :name
    node :display_value do |artist|
      "#{artist.name} (ID: #{artist.id})"
    end
  end
end

child :entry_scribes, :object_root => false do
  attributes :id
  child :scribe do
    attributes :id, :name
    node :display_value do |scribe|
      "#{scribe.name} (ID: #{scribe.id})"
    end
  end
end

child :entry_languages, :object_root => false do
  attributes :id
  child :language  do
    attributes :id, :name
    node :display_value do |language|
      "#{language.name} (ID: #{language.id})"
    end
  end
end

child :entry_materials, :object_root => false do
  attributes :id, :material
end

child :entry_places, :object_root => false do
  attributes :id
  child :place do
    attributes :id, :name
    node :display_value do |place|
      "#{place.name} (ID: #{place.id})"
    end
  end
end

child :entry_uses, :object_root => false do
  attributes :id, :use
end

child :events, :object_root => false do
  attributes :id, :primary, :comment, :acquire_date, :end_date, :price, :currency, :other_currency, :sold
  child :event_agents, :object_root => false do
    attributes :id, :observed_name, :role
    child :agent do |agent|
      attributes :id, :name
      node :display_value do |agent|
        "#{agent.name} (ID: #{agent.id})"
      end
    end
  end
end

child :entry_comments, :object_root => false do
  attributes :id, :comment, :date
  node :created_by do |entry_comment|
    entry_comment.created_by ? "#{entry_comment.created_by.username}" : nil
  end
end
