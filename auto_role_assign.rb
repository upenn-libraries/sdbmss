TYPES_ROLES = {
  workshop: "Work", 
  style: "Styl", 
  circle: "Circ", 
  school: "Scho", 
  associate: "Asso", 
  associates: "Assos", 
  atelier: "Atel", 
  artist: "Arti", 
  group: "Grou", 
  styles: "Styl", 
  follower: "Foll", 
  descendant: "Desc", 
  followers: "Foll", 
  contemporary: "Cont", 
  son: "Son", 
  manner: "Mann", 
  miniatures: "Mini", 
  provincial: "Prov", 
  pupil: "Pupi", 
  collaborators: "Coll",
  master: "Mast",
  assistant: "Assi",
  related: "Rela"
}

roles = [ 
  'collaborators',
  'miniatures',
  'followers',
  'associates',
  'styles',
  'circle',
  'school',
  'workshop',
  'associate',
  'atelier',
  'artist',
  'group',
  'follower',
  'descendant',
  'contemporary',
  'son',
  'manner',
  'pupil',
  'master',
  'assistant',
  'related',
  'style'
]

roles.each do |role|
  puts "role: #{role}"
  Name.where("name like '%, #{role}'").each do |name|
    new_name = name.name.gsub(", #{role}", "")
    matching_names = Name.where("name like ?", new_name)
    # if name already exists!
    name.entry_artists.each do |entry_artist|
      entry_artist.update_column(:role, role.to_sym)
    end

    if matching_names.count == 1 && matching_names.last.is_artist
      name.merge_into(matching_names.last)
    elsif matching_names.count > 1
      puts "Error: more than one name matches '#{new_name}'"
    elsif matching_names.count == 1 && !matching_names.last.is_artist
      puts "Error: matching name for #{new_name} -> #{matching_names.last.id}: #{matching_names.last.name} is not an artist"
    else
      name.update_column(:name, new_name)
    end
  end
end

# NOTE: multiple 'school' or 'workshops' based around place names that seem to exist as non-artists in name authority.  should flag be set and the names merged?

=begin
 
Error: matching name for Battista De Cingoli -> 12439: Battista De Cingoli is not an artist
Error: matching name for Paris -> 6963: Paris is not an artist
Error: matching name for Bourgogne -> 24020: Bourgogne is not an artist
Error: matching name for Luxembourg -> 32164: Luxembourg is not an artist
Error: matching name for Naples -> 9818: naples is not an artist
Error: matching name for Raphael -> 35013: Raphael is not an artist
Error: matching name for Sultan Muhammad -> 14017: Sultan Muhammad is not an artist
Error: matching name for Van Dyck -> 10122: van dyck is not an artist
Error: matching name for Shah Tahmasp -> 36068: Shah Tahmasp is not an artist
Error: matching name for Troyes -> 9674: TROYES is not an artist
Error: matching name for Winchester -> 38317: Winchester is not an artist
Error: matching name for Albi -> 7221: Albi is not an artist
Error: matching name for Tours -> 37202: Tours is not an artist
Error: matching name for Fontainebleau -> 28779: Fontainebleau is not an artist
Error: matching name for Flemish -> 15225: Flemish is not an artist
Error: matching name for Bologna -> 7267: Bologna is not an artist
Error: matching name for Corbie -> 25899: Corbie is not an artist
Error: matching name for Paris -> 6963: Paris is not an artist
Error: matching name for Rouen -> 7332: Rouen is not an artist
Error: matching name for Vespasiano da Bisticci -> 1814: Vespasiano da Bisticci is not an artist
Error: matching name for Delisle -> 27514: Delisle is not an artist
Error: matching name for Paris -> 6963: Paris is not an artist
Error: matching name for Tours -> 37202: Tours is not an artist
Error: matching name for Fouquet, Nicolas -> 28851: Fouquet, Nicolas is not an artist

=end