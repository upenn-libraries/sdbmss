object @author
attributes :id, :name
node :display_value do |author|
  "#{author.name} (ID: #{author.id})"
end
