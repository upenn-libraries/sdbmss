object @source
attributes :id, :date, :title, :source_type, :author, :whether_mss, :status, :current_location, :location_city, :location_country, :link, :cataloging_type, :electronic_catalog_format, :electronic_publicly_available, :comments, :entries_have_a_transaction

child :source_agents, :object_root => false do
  attributes :id, :role
  child :agent do |agent|
    attributes :id, :name
  end
end
