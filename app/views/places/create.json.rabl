object @place
attributes :id, :name
node :display_value do |place|
  "#{place.name} (ID: #{place.id})"
end
