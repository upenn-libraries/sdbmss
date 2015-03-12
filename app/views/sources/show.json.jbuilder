
json.(@source, :id, :display_value, :title, :source_type, :author, :whether_mss, :status, :medium, :date_accessed, :location_institution, :location, :link, :comments, :entries_have_a_transaction, :entries_have_institution)

json.date SDBMSS::Util::date_dashes(@source.date)

json.source_agents @source.source_agents do |source_agent|
  json.(source_agent, :id, :role)
  if source_agent.agent
    json.agent do
      json.(source_agent.agent, :id, :name)
    end
  end
end
