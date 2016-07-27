

require 'csv'

#confirmed

ids = []
CSV.foreach('confirmed_ids.csv') do |row|
  ids = row
end

ids = ids.map { |id| id.to_i }

puts "To confirm: #{Name.where(id: ids).count}"
Name.where(id: ids).update_all(confirmed: true)

#reviewed

ids = []
CSV.foreach('reviewed_ids.csv') do |row|
  ids = row
end

ids = ids.map { |id| id.to_i }

puts "To review: #{Name.where(id: ids).count}"
Name.where(id: ids).update_all(reviewed: true)

#as recorded

ids = []
CSV.foreach('as_recorded_ids.csv') do |row|
  ids = row
end

ids = ids.map { |id| id.to_i }

Name.where(id: ids).each do |name|
  EntryAuthor.where(author_id: name.id).update_all({observed_name: name.name, author_id: nil})
  EntryArtist.where(artist_id: name.id).update_all({observed_name: name.name, artist_id: nil})
  EntryScribe.where(scribe_id: name.id).update_all({observed_name: name.name, scribe_id: nil})
  Provenance.where(provenance_agent_id: name.id).update_all({observed_name: name.name, provenance_agent_id: nil})

  if name.source_agents.count + name.sale_agents.count <= 0
    name.delete
    puts "#{name.name}, #{name.id} deleted"
  else
    puts "#{name.name}, #{name.id} used as source/sale agents"
  end
end

Name.delay.index