object @source
attributes :id
node :display_value do |source|
  "#{source.get_display_value} (ID: #{source.id})"
end
