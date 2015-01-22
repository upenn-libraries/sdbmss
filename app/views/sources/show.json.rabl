object @source
attributes :id, :date, :title, :source_type, :author, :whether_mss, :status, :current_location, :location_city, :location_country, :link, :cataloging_type, :electronic_catalog_format, :electronic_catalog_open_access, :comments

node :display_value do |source|
  "#{source.get_display_value} (ID: #{source.id})"
end

child :source_agents, :object_root => false do
  attributes :id, :role
  child :agent do |agent|
    attributes :id, :name
    node :display_value do |agent|
      "#{agent.name} (ID: #{agent.id})"
    end
  end
end
