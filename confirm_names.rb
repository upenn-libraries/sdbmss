require 'csv'

#confirmed

ids = []
CSV.foreach('confirmed_ids.csv') do |row|
  ids = row
end

ids = ids.map { |id| id.to_i }

Name.where(id: ids).update_all(confirmed: true)

#reviewed

ids = []
CSV.foreach('reviewed_ids.csv') do |row|
  ids = row
end

ids = ids.map { |id| id.to_i }

Name.where(id: ids).update_all(reviewed: true)

#as recorded

ids = []
CSV.foreach('as_recorded.csv') do |row|
  ids = row
end

ids = ids.map { |id| id.to_i }

Name.where(id: ids).each do |name|
  name.entry_authors.each do |e|
    e.update(as_recorded: name.name)
  end

  name.entry_artists.each do |e|
    e.update(as_recorded: name.name)
  end

  name.entry_scribes.each do |e|
    e.update(as_recorded: name.name)
  end

  name.provenance.each do |e|
    e.update(as_recorded: name.name)
  end

  name.delete
end