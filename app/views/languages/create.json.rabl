object @language
attributes :id, :name
node :display_value do |language|
  "#{language.name} (ID: #{language.id})"
end
