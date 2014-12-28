object @agent
attributes :id, :name
node :display_value do |agent|
  "#{agent.name} (ID: #{agent.id})"
end
