object @scribe
attributes :id, :name
node :display_value do |scribe|
  "#{scribe.name} (ID: #{scribe.id})"
end
