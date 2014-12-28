object @artist
attributes :id, :name
node :display_value do |artist|
  "#{artist.name} (ID: #{artist.id})"
end
