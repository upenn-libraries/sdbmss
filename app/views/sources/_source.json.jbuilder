
json.(source, :id, :date, :display_value, :title, :source_type_id, :author, :whether_mss, :status, :medium, :date_accessed, :location_institution, :location, :link, :other_info)

json.source_type do
  json.(source.source_type, :id, :name, :display_name, :entries_have_institution_field, :entries_transaction_field)
end

json.source_agents source.source_agents do |source_agent|
  json.(source_agent, :id, :role, :observed_name)
  if source_agent.agent
    json.agent do
      json.(source_agent.agent, :id, :name)
    end
  end
end

if current_user
  json.backup current_user.backup
  json.username current_user.username
  json.user_id current_user.id
end